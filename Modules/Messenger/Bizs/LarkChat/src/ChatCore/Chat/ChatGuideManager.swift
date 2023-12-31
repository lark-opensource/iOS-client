//
//  ChatGuideManager.swift
//  LarkChat
//
//  Created by zc09v on 2018/10/15.
//

import UIKit
import Foundation
import LarkCore
import LarkKeyboardView
import LarkModel
import LarkMessengerInterface
import LarkUIKit
import LarkGuide
import RichLabel
import LarkMessageBase
import LarkMessageCore
import LarkFeatureGating
import LarkAccountInterface
import LarkGuideUI
import RustPB
import LarkContainer
import LarkSDKInterface
import UniverseDesignTabs
import LarkTourInterface
import LKRichView
import RxSwift
import LKCommonsLogging
import LarkRichTextCore

enum GuideType {
    case pin(Message)
    case atUser(Message)
    case readStatus(Message)
    case postHint(ChatKeyboardView?)
    case newOnboarding(ChatKeyboardView?)
    case typingTranslateOnboarding(ChatKeyboardView?)
    case specialFocus(Chat)
    // +号菜单的“定时发送”入口
    case scheduleSendExpandButton(Chat, ChatKeyboardView?)
    // 小飞机引导
    case sendButtonScheduleSend(Chat, ChatKeyboardView?)
}

// MARK: - ChatBaseGuideManager
final class ChatBaseGuideManager: UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(ChatBaseGuideManager.self, category: "Module.IM.Message")

    @ScopedInjectedLazy var guideManager: GuideService?
    @ScopedInjectedLazy var newGuideManager: NewGuideService?
    @ScopedInjectedLazy var tourService: TourChatGuideService?
    @ScopedInjectedLazy var scheduleSendService: ScheduleSendService?
    @ScopedInjectedLazy var chatterAPI: ChatterAPI?
    @ScopedInjectedLazy var chatAPI: ChatAPI?

    private let disposeBag = DisposeBag()
    private var currentChatterId: String {
        userResolver.userID
    }
    unowned let chatBaseVC: ChatMessagesViewController
    //提示气泡
    fileprivate var hintBubbleView: EasyhintBubbleView?
    // 是否移除+号定时发送引导
    private var isRemoveExpandScheduleGuide = false

    init(chatBaseVC: ChatMessagesViewController) {
        self.chatBaseVC = chatBaseVC
        self.userResolver = chatBaseVC.userResolver
    }

    deinit {
        print("NewChat: ChatBaseGuideManager deinit")
    }

    func checkShowGuideIfNeeded(_ guideType: GuideType) {
        switch guideType {
        case .pin(let message):
            checkShowPinGuideIfNeeded(message: message)
        case .atUser(let message):
            checkShowAtUserGuideIfNeeded(message: message)
        case .readStatus(let message):
            checkShowReadStatusGuideIfNeed(message: message)
        case .postHint(let keyboardView):
            checkShowPostHint(keyboardView)
        case .newOnboarding(let keyboardView):
            checkShowNewOnboardingGuideIfNeeded(keyboardView)
        case .typingTranslateOnboarding(let keyboardView):
            checkShowTypingTranslateOnboarding(keyboardView)
        case .specialFocus(let chat):
            checkRequestSpecialFocusGuidanceIfNeed(chat: chat)
        case .scheduleSendExpandButton(let chat, let keyboardView):
            checkScheduleSendExpandButtonGuide(chat: chat, keyboardView: keyboardView)
        case .sendButtonScheduleSend(let chat, let keyboardView):
            checkSendButtonScheduleSendGuide(chat: chat, keyboardView: keyboardView)
        }
    }

    func removeHintBubbleView() {
        self.hintBubbleView?.removeFromSuperview()
        self.hintBubbleView = nil
    }

    func shouldShowNewOnboardingGuide() -> Bool {
        return chatViewIsReady() && self.tourService?.needShowChatUserGuide(for: self.chatBaseVC.chat.value.id) == true
    }
}

extension ChatBaseGuideManager {
    private func checkShowPinGuideIfNeeded(message: Message) {
        // 由于此时 message 是假消息 所以需要自己判断 message isAtAll
        let isAtAll = { (message: Message) -> Bool in
            var richText: RustPB.Basic_V1_RichText?
            if let content = message.content as? TextContent {
                richText = content.richText
            } else if let content = message.content as? PostContent {
                richText = content.richText
            }

            guard let rich = richText else {
                return false
            }

            if rich.atIds.firstIndex(where: { (id) -> Bool in
                if let element = rich.elements[id],
                    element.tag == .at,
                    element.property.at.userID == "all" {
                    return true
                }
                return false
            }) != nil {
                return true
            }
            return false
        }
        guard chatViewIsReady(),
            message.isMeSend(userId: userResolver.userID),
            message.type == .text || message.type == .post,
            message.localStatus == .fakeSuccess || message.localStatus == .process,
            isAtAll(message),
            let indexPath = self.chatBaseVC.chatMessageViewModel.findMessageIndexBy(id: message.id),
            let cell = self.chatBaseVC.tableView.cellForRow(at: indexPath) as? MessageCommonCell else {
                return
        }

        let contentView: UIView
        guard let richView = cell.getView(by: PostViewComponentConstant.contentKey) as? LKRichView else { return }
        contentView = richView
        defer {
            ChatTracker.trackPinGuideShow()
        }

        let addPinGuideKey = "all_add_pin"
        newGuideManager?.showBubbleGuideIfNeeded(
            guideKey: addPinGuideKey,
            bubbleType: .single(SingleBubbleConfig(
                delegate: nil,
                bubbleConfig: BubbleItemConfig(
                    guideAnchor: TargetAnchor(
                        targetSourceType: .targetView(contentView),
                        arrowDirection: .down,
                        targetRectType: .rectangle
                    ),
                    textConfig: TextInfoConfig(detail: BundleI18n.LarkChat.Lark_Pin_PinGuideTips)
                )
            )),
            customWindow: contentView.window,
            dismissHandler: nil
        )
    }

    private func checkShowAtUserGuideIfNeeded(message: Message) {
        guard chatViewIsReady(),
            message.isMeSend(userId: userResolver.userID),
              message.localStatus == .fakeSuccess || message.localStatus == .process else {
            return
        }
        let messageId = message.id
        self.checkIsOnlyAtBot(message.content)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (onlyAtBot) in
                guard let self = self else { return }
                guard !onlyAtBot,
                        let indexPath = self.chatBaseVC.chatMessageViewModel.findMessageIndexBy(id: messageId) else { return }
                self.showAtUserGuide(indexPath)
            }).disposed(by: self.disposeBag)
    }

    private func showAtUserGuide(_ indexPath: IndexPath) {
        let mentionStatusGuideKey = "mobile_mention_status"
        let convertRect: CGRect
        let contentView: UIView
        guard let cell = self.chatBaseVC.tableView.cellForRow(at: indexPath) as? MessageCommonCell,
              let richView = cell.getView(by: PostViewComponentConstant.contentKey) as? LKRichView,
              let rect = richView.findElement(by: RichViewAdaptor.Tag.point).first?.1
            else {
            return
        }
        contentView = richView
        convertRect = self.chatBaseVC.view.window?.convert(rect, from: richView) ?? .zero
        guard let image = BundleI18n.image(
            named: "guide_at_read", in: BundleConfig.LarkChatBundle, compatibleWith: nil
        ) else {
            return
        }
        newGuideManager?.showBubbleGuideIfNeeded(
            guideKey: mentionStatusGuideKey,
            bubbleType: .single(SingleBubbleConfig(
                delegate: nil,
                bubbleConfig: BubbleItemConfig(
                    guideAnchor: TargetAnchor(
                        targetSourceType: .targetRect(convertRect),
                        arrowDirection: .down,
                        targetRectType: .circle
                    ),
                    textConfig: TextInfoConfig(detail: ""),
                    bannerConfig: BannerInfoConfig(imageType: .image(image)),
                    bottomConfig: BottomConfig(rightBtnInfo: ButtonInfo(
                        title: BundleI18n.LarkChat.Lark_Legacy_IKnow, buttonType: .close
                    ))
                ),
                maskConfig: MaskConfig()
            )),
            customWindow: contentView.window,
            dismissHandler: nil
        )
    }

    private func checkShowReadStatusGuideIfNeed(message: Message) {
        guard chatViewIsReady(),
            !self.chatBaseVC.chat.value.isSingleBot,
            message.isMeSend(userId: userResolver.userID),
            message.localStatus == .success,
            let indexPath = self.chatBaseVC.chatMessageViewModel.findMessageIndexBy(id: message.id) else {
                return
        }

        let cell = { [weak self] in
            return self?.chatBaseVC.tableView.cellForRow(at: indexPath) as? MessageCommonCell
        }
        guard let readButtonView = cell()?.getView(by: StatusComponentConstant.readStatusButtonKey) else { return }

        let readStatusGuideKey = "mobile_read_status"

        if let image = BundleI18n.image(named: "guide_read_status", in: BundleConfig.LarkChatBundle, compatibleWith: nil) {
            newGuideManager?.showBubbleGuideIfNeeded(
                guideKey: readStatusGuideKey,
                bubbleType: .single(SingleBubbleConfig(
                    delegate: nil,
                    bubbleConfig: BubbleItemConfig(
                        guideAnchor: TargetAnchor(
                            targetSourceType: .targetView(readButtonView),
                            arrowDirection: .down,
                            targetRectType: .circle
                        ),
                        textConfig: TextInfoConfig(detail: ""),
                        bannerConfig: BannerInfoConfig(imageType: .image(image)),
                        bottomConfig: BottomConfig(rightBtnInfo: ButtonInfo(
                            title: BundleI18n.LarkChat.Lark_Legacy_IKnow, buttonType: .close
                        ))
                    ),
                    maskConfig: MaskConfig()
                )),
                customWindow: readButtonView.window,
                dismissHandler: nil
            )
        }
    }

    private func checkShowPostHint(_ keyboardView: ChatKeyboardView?) {
        let richTextGuideKey = "mobile_rich_text"
        guard let keyboardView = keyboardView else {
                return
        }

        newGuideManager?.showBubbleGuideIfNeeded(
            guideKey: richTextGuideKey,
            bubbleType: .single(SingleBubbleConfig(
                delegate: nil,
                bubbleConfig: BubbleItemConfig(
                    guideAnchor: TargetAnchor(
                        targetSourceType: .targetView(keyboardView.expandButton),
                        arrowDirection: .down,
                        targetRectType: .rectangle
                    ),
                    textConfig: TextInfoConfig(detail: BundleI18n.LarkChat.Lark_Legacy_GuidePostButtonHint)
                )
            )),
            customWindow: keyboardView.expandButton.window,
            dismissHandler: nil
        )
    }

    private func checkShowNewOnboardingGuideIfNeeded(_ keyboardView: ChatKeyboardView?) {
        guard chatViewIsReady(),
              self.tourService?.needShowChatUserGuide(for: chatBaseVC.chat.value.id) == true,
            let keyboardView = keyboardView else {
            return
        }
        let keyboardRect = keyboardView.convert(keyboardView.bounds, to: nil)
        let targetRect = CGRect(x: keyboardRect.minX + 16.0,
                                y: keyboardRect.minY + 10.0,
                                width: 70.0, height: 24.0)
        self.tourService?.showChatUserGuideIfNeeded(
            with: chatBaseVC.chat.value.id,
            on: targetRect,
            completion: nil
        )
    }

    private func checkShowTypingTranslateOnboarding(_ keyboardView: ChatKeyboardView?) {
        let key = PageContext.GuideKey.typingTranslateOnboarding
        guard let targetView = keyboardView?.keyboardPanel.getButton(KeyboardItemKey.more.rawValue) else { return }
        let guideAnchor = TargetAnchor(targetSourceType: .targetView(targetView), offset: 0, targetRectType: .circle)
        let textInfoConfig = TextInfoConfig(detail: BundleI18n.LarkChat.Lark_IM_TranslationAsYouType_ClickOnMoreToEnable_OnboardingMessage)
        let item = BubbleItemConfig(guideAnchor: guideAnchor, textConfig: textInfoConfig)
        let singleBubbleConfig = SingleBubbleConfig(delegate: nil, bubbleConfig: item)
        self.newGuideManager?.showBubbleGuideIfNeeded(guideKey: key,
                                                     bubbleType: .single(singleBubbleConfig),
                                                     dismissHandler: nil)
    }

    func viewWillTransition() {
        // 转屏时移除定时消息引导，避免位置错乱
        if self.isRemoveExpandScheduleGuide {
            self.isRemoveExpandScheduleGuide = false
            self.newGuideManager?.closeCurrentGuideUIIfNeeded()
        }
    }

    private func checkScheduleSendExpandButtonGuide(chat: Chat, keyboardView: ChatKeyboardView?) {
        guard let scheduleSendService, scheduleSendService.scheduleSendEnable else { return }
        guard ScheduleSendManager.chatCanScheduleSend(chat) else { return }
        // 有“lark”发送按钮不显示此引导
        if let btn = (keyboardView?.keyboardPanel as? MessengerKeyboardPanel)?.getSendButton(), btn is DefaultKeyboardSendButton {
            return
        }
        // 只有不是自己的单聊才显示引导
        guard chat.type == .p2P, chat.chatterId != currentChatterId else { return }
        guard let timeZoneId = chat.chatter?.timeZoneID else {
            Self.logger.info(logId: "checkScheduleSendExpandButtonGuide return, timeZoneId is nil")
            return
        }
        guard scheduleSendService.checkTimezoneCanShowGuide(timezone: timeZoneId) else {
            Self.logger.info(logId: "checkScheduleSendExpandButtonGuide return, checkTimezoneCanShowGuide is false")
            return
        }

        let key = "im_chat_message_schedule_send_expand_button"
        guard let targetView = keyboardView?.keyboardPanel.getButton(KeyboardItemKey.more.rawValue) else {
            Self.logger.info(logId: "checkScheduleSendExpandButtonGuide return, getButton is false")
            return
        }
        // 避免取到的frame是空
        if targetView.frame == .zero {
            targetView.superview?.layoutIfNeeded()
        }
        let guideAnchor = TargetAnchor(targetSourceType: .targetView(targetView), offset: 0, arrowDirection: .right, targetRectType: .circle, ignoreSafeArea: true)
        let textInfoConfig = TextInfoConfig(detail: BundleI18n.LarkChat.Lark_IM_ScheduleMessage_TryTheNewFeature_Onboard)
        let item = BubbleItemConfig(guideAnchor: guideAnchor, textConfig: textInfoConfig)
        let singleBubbleConfig = SingleBubbleConfig(delegate: nil, bubbleConfig: item)

        self.newGuideManager?.showBubbleGuideIfNeeded(guideKey: key,
                                                     bubbleType: .single(singleBubbleConfig),
                                                     dismissHandler: { [weak self] in
            self?.isRemoveExpandScheduleGuide = false
        },
                                                     didAppearHandler: nil,
                                                     willAppearHandler: { [weak self] guideKey in
            if guideKey == key {
                self?.isRemoveExpandScheduleGuide = true
            }
        })
    }

    // 小飞机定时发送引导
    func checkSendButtonScheduleSendGuide(chat: Chat, keyboardView: ChatKeyboardView?) {
        guard let scheduleSendService, scheduleSendService.scheduleSendEnable else { return }
        guard ScheduleSendManager.chatCanScheduleSend(chat) else { return }
        guard let sendBtn = (keyboardView as? NormalChatKeyboardView)?.getCurrentDisplaySendBtn() else { return }

        // 只有不是自己的单聊才显示引导
        guard chat.type == .p2P, chat.chatterId != currentChatterId else { return }
        guard let timeZoneId = chat.chatter?.timeZoneID else { return }
        guard scheduleSendService.checkTimezoneCanShowGuide(timezone: timeZoneId) else { return }

        let guideKey = "im_chat_message_schedule_send_button"
        newGuideManager?.showBubbleGuideIfNeeded(
            guideKey: guideKey,
            bubbleType: .single(SingleBubbleConfig(
                delegate: nil,
                bubbleConfig: BubbleItemConfig(
                    guideAnchor: TargetAnchor(
                        targetSourceType: .targetView(sendBtn),
                        offset: 0,
                        arrowDirection: .right,
                        targetRectType: .circle,
                        ignoreSafeArea: true
                    ),
                    textConfig: TextInfoConfig(detail: BundleI18n.LarkChat.Lark_IM_ScheduleMessage_TapToTryTheNewFeature_Onboard)
                )
            )),
            dismissHandler: nil
        )
    }

    //这里不是展示guide，而是通过系统消息的方式来引导用户
    private func checkRequestSpecialFocusGuidanceIfNeed(chat: Chat) {
        guard chat.type == .p2P,
              let chatterId = Int64(chat.chatterId) else { return }
        chatAPI?.specialFocusGuidance(targetUserID: chatterId)
            .subscribe(onNext: { res in
                Self.logger.info("specialFocusGuidance succeed, sendSystemMessage: \(res.isSendSystemMessage)")
            }).disposed(by: self.disposeBag)
    }

    func chatViewIsReady() -> Bool {
        guard self.chatBaseVC.isViewLoaded && self.chatBaseVC.view.window != nil else {
            return false
        }
        return true
    }

    /// 检查是不是仅仅@了机器人
    private func checkIsOnlyAtBot(_ content: MessageContent) -> Observable<Bool> {
        var atChatterIDs: Set<String>?
        if let content = content as? TextContent {
            atChatterIDs = content.atUserIdsSet
        } else if let content = content as? PostContent {
            atChatterIDs = content.atUserIdsSet
        }

        if atChatterIDs?.count == 1,
           let chatterId = atChatterIDs?.first,
           let chatterAPI = self.chatterAPI {
            return chatterAPI.getChatter(id: chatterId)
                .map { (chatter) -> Bool in
                    return chatter?.type == .bot
                }
        }
        return .just(false)
    }
}
