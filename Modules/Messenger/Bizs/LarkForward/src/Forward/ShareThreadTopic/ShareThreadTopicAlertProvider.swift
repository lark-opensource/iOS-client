//
//  ShareThreadTopicAlertProvider.swift
//  LarkForward
//
//  Created by zc09v on 2019/6/17.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import UniverseDesignToast
import LarkSDKInterface
import LarkSendMessage
import LarkMessengerInterface
import LarkAlertController
import EENavigator
import LarkContainer
import LarkRichTextCore
import LarkSetting
import LKCommonsTracker
import LKCommonsLogging
import Homeric
import LarkUIKit
import LarkBaseKeyboard
import AppReciableSDK

struct ShareThreadTopicAlertContent: ForwardAlertContent {
    let message: Message
    let title: String
}

// nolint: duplicated_code -- v2转发代码，v3转发全业务GA后可删除
final class ShareThreadTopicAlertProvider: ForwardAlertProvider {
    @ScopedInjectedLazy var chatSecurity: ChatSecurityControlService?
    private static let logger = Logger.log(ShareThreadTopicAlertProvider.self, category: "ShareThreadTopicAlertProvider")
    var disposeBag = DisposeBag()
    /// 转发内容一级预览FG开关
    private lazy var forwardDialogContentFG: Bool = {
        return userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.dialog_content_new"))
    }()
    /// 转发内容二级预览FG开关
    private lazy var forwardContentPreviewFG: Bool = {
        return userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core_forward_content_preview"))
    }()
    /// 话题转发卡片
    private lazy var enableThreadForwardCard: Bool = {
        return userResolver.fg.staticFeatureGatingValue(with: "messenger.message.new_thread_forward_card")
    }()

    override var shouldCreateGroup: Bool {
        return false
    }

    override var isSupportMention: Bool {
        return true
    }

    override func isShowInputView(by items: [ForwardItem]) -> Bool {
        return true
    }

    override func getFilter() -> ForwardDataFilter? {
        return { return !$0.isCrossTenant }
    }

    override func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        guard let postContent = content as? ShareThreadTopicAlertContent else { return nil }
        let includeConfigs: IncludeConfigs = [
            //业务需要置灰外部人，外部群，帖子
            ForwardUserEnabledEntityConfig(tenant: .inner),
            ForwardGroupChatEnabledEntityConfig(tenant: .inner),
            ForwardBotEnabledEntityConfig()
        ]
        return includeConfigs
    }

    override func getTitle(by items: [ForwardItem]) -> String? {
        return BundleI18n.LarkForward.Lark_Chat_TopicToolShareTo
    }

    override class func canHandle(content: ForwardAlertContent) -> Bool {
        return content is ShareThreadTopicAlertContent
    }

    override func getContentView(by items: [ForwardItem]) -> UIView? {
        guard let content = content as? ShareThreadTopicAlertContent,
              let chatSecurity = self.chatSecurity,
              let modelService = try? userResolver.resolve(assert: ModelService.self)
        else { return nil }
        let message = content.message
        var view: UIView?
        if forwardDialogContentFG {
            let baseView = ForwardConfirmFooterGenerator(userResolver: userResolver).generatorThreadDetailConfirmFooter(message: message)
            baseView.didClickAction = { [weak self] in
                guard let self = self else { return }
                self.didClickThreadDetailForwardAlert()
            }
            return baseView
        }
        switch message.type {
        case .text:
            view = ForwardTextMessageConfirmFooter(message: message, modelService: modelService)
        case .sticker:
            view = ForwardImageMessageConfirmFooter(message: message,
                                                    modelService: modelService,
                                                    image: nil,
                                                    hasPermissionPreview: true)
        case .image:
            let permissionPreview = chatSecurity.checkPermissionPreview(anonymousId: "", message: message)
            view = ForwardImageMessageConfirmFooter(message: message,
                                                    modelService: modelService,
                                                    image: nil,
                                                    hasPermissionPreview: permissionPreview.0)
        case .shareUserCard:
            view = ForwardUserCardMessageConfirmFooter(message: message)
        case .media:
            let permissionPreview = chatSecurity.checkPermissionPreview(anonymousId: "", message: message)
            view = ForwardVideoMessageConfirmFooter(message: message, modelService: modelService, hasPermissionPreview: permissionPreview.0)
        case .file, .folder:
            let permissionPreview = chatSecurity.checkPermissionPreview(anonymousId: "", message: message)
            view = ForwardFileAndFolderMessageConfirmFooter(message: message, hasPermissionPreview: permissionPreview.0)
        case .post:
            // 产品需求：Thread中post按照text显示方式处理。
            view = ForwardTextMessageConfirmFooter(message: message, modelService: modelService)
        case .mergeForward:
            if (message.content as? MergeForwardContent)?.isFromPrivateTopic ?? false {
                return nil
            }
            view = MergeForwardConfirmFooter(message: message)
        case .audio:
            view = ForwardAudioMessageConfirmFooter(message: message, userResolver: userResolver)
        case .shareGroupChat:
            view = ForwardShareGroupConfirmFooter(message: message, modelService: modelService)
        case .unknown,
             .system,
             .email,
             .calendar,
             .card,
             .shareCalendarEvent,
             .hongbao,
             .commercializedHongbao,
             .generalCalendar,
             .videoChat,
             .location,
             .todo,
             .diagnose,
             .vote:
            break
        @unknown default:
            assert(false, "new value")
            break
        }
        return view
    }

    override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        if self.enableThreadForwardCard {
            return mergeForwardThread(items: items, input: input, from: from)
        } else {
            return shareThread(items: items, input: input, from: from)
        }
    }

    private func shareThread(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let content = content as? ShareThreadTopicAlertContent,
              let window = from.view.window,
              let threadAPI = try? resolver.resolve(assert: ThreadAPI.self)
        else { return .empty() }
        var tracker = ShareAppreciableTracker(pageName: "ForwardViewController", fromType: .topic)
        tracker.start()

        let message = content.message
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        let startTime = CACurrentMediaTime()
        return self.checkAndCreateChats(chatIds: ids.chatIds, userIds: ids.userIds)
            .flatMap({ (chats) -> Observable<[String]> in
                let chatIds = chats.map({ $0.id })
                return threadAPI.shareThreadTopic(threadId: message.threadId,
                                                  chatId: message.channel.id,
                                                  toChatIds: chatIds)
                    .map({ return chatIds })
            }).observeOn(MainScheduler.instance)
            .do(onNext: { (_) in
                hud.remove()
                tracker.end(sdkCost: CACurrentMediaTime() - startTime)
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                shareErrorHandler(userResolver: self.userResolver,
                                  hud: hud,
                                  on: from,
                                  error: error)
                tracker.error(error)
            })
    }

    private func mergeForwardThread(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let content = content as? ShareThreadTopicAlertContent else {
            return .empty()
        }
        Tracer.trackMergeForwardConfirm()
        let ids = self.itemsToIds(items)
        let threadIDAndChatIDs = items.filter { $0.type.isThread }.map { ($0.id, $0.channelID ?? "") }
        let ob = BehaviorSubject<[String]>(value: []).asObserver()

        MergeForwardAlertProvider.mergeForwardThread(
            resolver: self.resolver,
            checkChatIDs: ids.chatIds,
            to: items.filter { $0.type == .chat }.map { $0.id },
            to: threadIDAndChatIDs,
            userIDs: ids.userIds,
            originMergeForwardId: nil,
            threadID: content.message.threadId,
            messageIds: [content.message.id],
            title: content.title,
            input: input,
            observer: ob,
            disposeBag: self.disposeBag,
            clearDisposeBag: { [weak self] in self?.clearDisposeBag() },
            afterForwardBlock: nil,
            userResolver: self.userResolver,
            from: from
        ).subscribe().disposed(by: self.disposeBag)

        return ob.do(onError: { error in
            //失败埋点
            AppReciableSDK.shared.error(
                params: ErrorParams(
                    biz: .Messenger,
                    scene: .Chat,
                    event: .mergeForwardMessage,
                    errorType: .SDK,
                    errorLevel: .Exception,
                    errorCode: (error as NSError).code,
                    userAction: nil,
                    page: "ForwardViewController",
                    errorMessage: (error as NSError).description,
                    extra: Extra(
                        isNeedNet: true,
                        category: [
                            "chat_type": "\(ForwardAppReciableTrackChatType.topic.rawValue)"
                        ],
                        extra: [
                            "chat_count": "\(ids.chatIds.count + ids.userIds.count)"
                        ]
                    )
                ))
        })
    }

    override func sureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        if self.enableThreadForwardCard {
            return mergeForwardThread(items: items, attributeInput: attributeInput, from: from)
        } else {
            return shareThread(items: items, attributeInput: attributeInput, from: from)
        }
    }

    private func shareThread(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        guard let content = content as? ShareThreadTopicAlertContent,
              let window = from.view.window,
              let threadAPI = try? resolver.resolve(assert: ThreadAPI.self),
              let messageAPI = try? resolver.resolve(assert: MessageAPI.self),
              let sendMessageAPI = try? resolver.resolve(assert: SendMessageAPI.self)
        else { return .empty() }
        var tracker = ShareAppreciableTracker(pageName: "ForwardViewController", fromType: .topic)
        tracker.start()
        let message = content.message
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        let startTime = CACurrentMediaTime()
        return self.checkAndCreateChats(chatIds: ids.chatIds, userIds: ids.userIds)
            .flatMap({ (chats) -> Observable<([String], [String: String])> in
                let chatIds = chats.map({ $0.id })
                return threadAPI.shareThreadTopicWithResp(threadId: message.threadId,
                                                  chatId: message.channel.id,
                                                  toChatIds: chatIds)
                    .map({ chatIdToMessageId in
                        return (chatIds, chatIdToMessageId)
                    })
            })
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] (result) in
                guard let `self` = self else {
                    return
                }
                var msgIds: [String] = []
                let chatIds = result.0
                let chatIdToMessageId = result.1
                for chatId in chatIds {
                    if let msgId = chatIdToMessageId[chatId] {
                        msgIds.append(msgId)
                    }
                }
                self.sendReplyMessage(messageAPI: messageAPI, sendMessageAPI: sendMessageAPI, attributeExtraText: attributeInput ?? NSAttributedString(string: ""), messageIDs: msgIds)
                hud.remove()
                tracker.end(sdkCost: CACurrentMediaTime() - startTime)
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                shareErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
                tracker.error(error)
            })
            .map { $0.0 }
    }

    private func mergeForwardThread(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        guard let content = content as? ShareThreadTopicAlertContent else {
            return .empty()
        }
        Tracer.trackMergeForwardConfirm()
        let ids = self.itemsToIds(items)
        let threadIDAndChatIDs = items.filter { $0.type.isThread }.map { ($0.id, $0.channelID ?? "") }
        let ob = BehaviorSubject<[String]>(value: []).asObserver()

        MergeForwardAlertProvider.mergeForwardThread(
            resolver: self.resolver,
            checkChatIDs: ids.chatIds,
            to: items.filter { $0.type == .chat }.map { $0.id },
            to: threadIDAndChatIDs,
            userIDs: ids.userIds,
            originMergeForwardId: nil,
            threadID: content.message.threadId,
            messageIds: [content.message.id],
            title: content.title,
            attributeInput: attributeInput,
            observer: ob,
            disposeBag: self.disposeBag,
            clearDisposeBag: { [weak self] in self?.clearDisposeBag() },
            afterForwardBlock: nil,
            userResolver: self.userResolver,
            from: from
        ).subscribe().disposed(by: self.disposeBag)

        return ob.do(onError: { error in
            //失败埋点
            AppReciableSDK.shared.error(
                params: ErrorParams(
                    biz: .Messenger,
                    scene: .Chat,
                    event: .mergeForwardMessage,
                    errorType: .SDK,
                    errorLevel: .Exception,
                    errorCode: (error as NSError).code,
                    userAction: nil,
                    page: "ForwardViewController",
                    errorMessage: (error as NSError).description,
                    extra: Extra(
                        isNeedNet: true,
                        category: [
                            "chat_type": "\(ForwardAppReciableTrackChatType.topic.rawValue)"
                        ],
                        extra: [
                            "chat_count": "\(ids.chatIds.count + ids.userIds.count)"
                        ]
                    )
                ))
        })
    }

    private func sendReplyMessage(messageAPI: MessageAPI, sendMessageAPI: SendMessageAPI, attributeExtraText: NSAttributedString, messageIDs: [String]) {
        if attributeExtraText.length != 0 {
            if var richText = RichTextTransformKit.transformStringToRichText(string: attributeExtraText) {
                richText.richTextVersion = 1
                messageAPI.fetchMessages(ids: messageIDs).subscribe(onNext: { [weak self] (messages) in
                    guard let `self` = self else {
                        return
                    }
                    // 对每一个chat中新转发生成message，发送一条回复。
                    messages.forEach({ (message) in
                        // 使用messageId 找出message实体，进行回复。
                        sendMessageAPI.sendText(
                            context: nil,
                            content: richText,
                            parentMessage: message,
                            chatId: message.channel.id,
                            threadId: nil,
                            stateHandler: nil
                        )
                    })
                }).disposed(by: self.disposeBag)
            }
        }
    }

    func didClickThreadDetailForwardAlert() {
        Tracker.post(TeaEvent(Homeric.IM_MSG_FORWARD_SELECT_CLICK,
                              params: ["click": "msg_detail",
                                       "target": "none"]))
        if !forwardContentPreviewFG { return }
        showTopicGroupThreadDetailContentPreview()
    }

    func showTopicGroupThreadDetailContentPreview() {
        guard let content = content as? ShareThreadTopicAlertContent else { return }
        Self.logger.info("Forward.ContentPreview: Public ThreadDetail Preview, threadID: \(content.message.threadId)")
        let body = ThreadDetailPreviewByIDBody(threadId: content.message.threadId, loadType: .root)
        guard let fromVC = self.targetVc else { return }
        self.userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: fromVC)
    }

    private func clearDisposeBag() {
        disposeBag = DisposeBag()
    }
}
