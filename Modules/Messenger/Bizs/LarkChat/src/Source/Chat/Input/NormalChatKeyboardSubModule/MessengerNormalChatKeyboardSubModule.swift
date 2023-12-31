//
//  MessengerNormalChatKeyboardSubModule.swift
//  LarkChat
//
//  Created by zhaojiachen on 2021/12/30.
//

import UIKit
import Foundation
import LarkReleaseConfig
import LarkOpenChat
import LarkOpenIM
import LarkFeatureSwitch
import LarkKAFeatureSwitch
import LarkFeatureGating
import LarkContainer
import RustPB
import LarkModel
import EENavigator
import LarkNavigation
import LarkUIKit
import LarkMessengerInterface
import LarkSDKInterface
import LarkCore
import SuiteAppConfig
import LarkAccountInterface
import LarkAlertController
import LarkRichTextCore
import EditTextView
import TangramService
import RxSwift
import UniverseDesignToast
import LKCommonsTracker
import Homeric
import LarkMessageCore
import LarkIMMention
import LarkBaseKeyboard
import LKCommonsLogging
import LarkGuide
import LarkPrivacySetting

struct ScheduleSendDraftModel {
    var isVaild = false
    var draftContent: String?
    var scheduleTime: Int64?
    var messageId: String?
}
import LarkSendMessage

protocol MessengerNormalChatKeyboardDependency: AnyObject {
    var assetManager: AssetPreProcessManager { get }
    var scheduleSendDraftChange: Observable<ScheduleSendDraftModel> { get }
    var returnType: UIReturnKeyType { get }
}

final class DefaultMessengerNormalChatKeyboardDependency: MessengerNormalChatKeyboardDependency {
    let userResolver: UserResolver
    var assetManager: AssetPreProcessManager { AssetPreProcessManager(userResolver: userResolver, isCrypto: false) }
    var scheduleSendDraftChange: Observable<ScheduleSendDraftModel> { .empty() }
    var returnType: UIReturnKeyType { .default }
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
}

public final class MessengerNormalChatKeyboardSubModule: NormalChatKeyboardSubModule {
    static let logger = Logger.log(MessengerNormalChatKeyboardSubModule.self, category: "Module.LarkChat")

    // MARK: - 「+」号菜单
    public override var moreItems: [ChatKeyboardMoreItem] {
        return _moreItems
    }
    private var _moreItems: [ChatKeyboardMoreItem] = []
    private var metaModel: ChatKeyboardMetaModel?

    @ScopedInjectedLazy var chatAPI: ChatAPI?
    @ScopedInjectedLazy var appConfigService: AppConfigService?
    @ScopedInjectedLazy var myAIService: MyAIService?

    private var disposeBag = DisposeBag()

    public override class func canInitialize(context: ChatKeyboardContext) -> Bool {
        return true
    }

    public override func canHandle(model: ChatKeyboardMetaModel) -> Bool {
        return true
    }

    public override func handler(model: ChatKeyboardMetaModel) -> [Module<ChatKeyboardContext, ChatKeyboardMetaModel>] {
        return [self]
    }

    public override func modelDidChange(model: ChatKeyboardMetaModel) {
        var needToRefresh = false
        if self.metaModel?.chat.typingTranslateSetting.isOpen != model.chat.typingTranslateSetting.isOpen {
            needToRefresh = true
        }
        self.metaModel = model
        if needToRefresh {
            self._moreItems = self.buildMoreItems(metaModel: model)
            self.context.refreshMoreItems()
        }
    }
    lazy var scheduleMsgEnable = scheduleSendService?.scheduleSendEnable ?? false

    private var draft: RustPB.Basic_V1_Draft?

    public override func createMoreItems(metaModel: ChatKeyboardMetaModel) {
        self.metaModel = metaModel
        self._moreItems = self.buildMoreItems(metaModel: metaModel)

        if scheduleMsgEnable == true {
            // observe data to reload scheduleSend item dot display or not
            self.context.getScheduleDraft
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] draft in
                    guard let self = self else { return }
                    let isShowDot = draft != nil
                    self.draft = draft
                    Self.logger.info("getScheduleDraft: isShowDot\(isShowDot), view.showDotBadge: \(self.scheduleSend?.showDotBadge)")
                    if isShowDot, self.scheduleSend?.showDotBadge == false {
                        self.scheduleSend?.showDotBadge = true
                        self._moreItems = self.buildMoreItems(metaModel: metaModel)
                        self.context.refreshMoreItems()
                    }
                }, onError: { (error) in
                    Self.logger.error("getScheduleDraft error", error: error)
                }).disposed(by: self.disposeBag)

            try? self.context.resolver.resolve(assert: MessengerNormalChatKeyboardDependency.self)
                .scheduleSendDraftChange
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] model in
                    guard let self = self else { return }
                    Self.logger.info("scheduleSendDraftChange model.isVaild: \(model.isVaild)")
                    func canHandle() -> Bool {
                        if model.messageId.isEmpty == false, self.context.hasRootMessage == false {
                            Self.logger.info("scheduleSendDraftChange abort by not detail page")
                            return false
                        }
                        if model.messageId.isEmpty == false, self.context.hasRootMessage, self.context.getRootMessage()?.id != model.messageId {
                            Self.logger.info("scheduleSendDraftChange abort by rootId not equal")
                            return false
                        }
                        Self.logger.info("scheduleSendDraftChange can handle")
                        return true
                    }
                    guard canHandle() else { return }
                    if model.isVaild == true {
                        self.draft?.messageID = model.messageId ?? ""
                        self.draft?.content = model.draftContent ?? ""
                        self.draft?.scheduleInfo.scheduleTime = model.scheduleTime ?? 0
                        Self.logger.info("scheduleSendDraftChange showDotBadge")
                        if self.scheduleSend?.showDotBadge == false {
                            self.scheduleSend?.showDotBadge = true
                            self._moreItems = self.buildMoreItems(metaModel: metaModel)
                            self.context.refreshMoreItems()
                        }
                        return
                    }
                    if model.isVaild == false, self.scheduleSend?.showDotBadge == true {
                        Self.logger.info("scheduleSendDraftChange showDotBadge")
                        self.scheduleSend?.showDotBadge = false
                        self.draft = nil
                        self._moreItems = self.buildMoreItems(metaModel: metaModel)
                        self.context.refreshMoreItems()
                    }
                }).disposed(by: self.disposeBag)
        }
    }

    private func buildMoreItems(metaModel: ChatKeyboardMetaModel) -> [ChatKeyboardMoreItem] {
        var items: [ChatKeyboardMoreItem] = [file, redPacket, vote, sendLocation, shareUserCard, realTimeTranslate, scheduleSend].compactMap { $0 }
        return items
    }

    // MARK: file
    private lazy var file: ChatKeyboardMoreItem? = {
        if self.context.hasRootMessage { return nil }
        if let myAIPageService = try? self.context.userResolver.resolve(type: MyAIPageService.self),
           myAIPageService.chatMode {
            //MyAI分会话去掉发文件入口。
            return nil
        }

        let item = ChatKeyboardMoreItemConfig(
            text: BundleI18n.LarkChat.Lark_Legacy_FileLabel,
            icon: Resources.cloud_file,
            type: .file,
            tapped: { [weak self] in
                self?.clickFile()
            })
        return item
    }()

    private func clickFile() {
        guard let generalSettings = try? self.context.resolver.resolve(assert: UserGeneralSettings.self) else { return }
        ChatTracker.trackSendAttachedFileIconClicked()
        if let chat = self.metaModel?.chat {
            IMTracker.Chat.InputPlus.Click.localFile(chat)
        }

        let chooseFileBlock: ([LocalAttachFile]) -> Void = { [weak self] (files) in
            guard let self = self else { return }
            files.forEach {
                self.context.sendFile(path: $0.fileURL.path, name: $0.name, parentMessage: nil)
            }
        }

        let chooseFileChangeBlock: ([String]) -> Void = { [weak self] (filesPath) in
            guard let assetManager = try? self?.context.resolver.resolve(assert: MessengerNormalChatKeyboardDependency.self).assetManager else { return }
            guard assetManager.checkEnableByType(fileType: .file) else {
                return
            }
            filesPath.forEach { filePath in
                //判断内存是否足够
                var memoryIsEnough: Bool = assetManager.checkMemoryIsEnough()
                //如果超过了最大限制，内存不足不再处理
                guard memoryIsEnough else {
                    return
                }
                //判断资源是否已经处理过
                let hasOperation = assetManager.checkAssetHasOperation(assetName: filePath)
                //没有处理创建任务添加到任务队列
                if !hasOperation {
                    let assetOperation = BlockOperation(block: {
                        //秒传预处理
                        assetManager.preProcessResource(filePath: filePath, data: nil, fileType: .file, assetName: filePath, imageSourceResult: nil)
                    })
                    //添加到队列中
                    assetManager.addAssetProcessOperation(assetOperation)
                    assetManager.addToPendingAssets(name: filePath, value: filePath)
                }
            }
        }

        let from = self.context.baseViewController()
        var body = LocalFileBody()
        // 获取settings下发的文件大小发送限制
        body.maxSingleFileSize = generalSettings.fileUploadSizeLimit.value.maxSingleFileSize
        body.maxTotalFileSize = generalSettings.fileUploadSizeLimit.value.maxTotalFileSize
        body.requestFrom = .im
        body.chooseLocalFiles = chooseFileBlock
        body.chooseFilesChange = chooseFileChangeBlock
        navigator.present(
            body: body,
            wrap: LkNavigationController.self,
            from: from,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
        )
    }

    // MARK: redPacket
    /// 红包开关
    private lazy var redPacketEnable: Bool = {
        guard let passportUserService = try? userResolver.resolve(assert: PassportUserService.self)
        else { return false }

        let featureSwitchEnable = userResolver.fg.staticFeatureGatingValue(with: .init(switch: .ttPay))
        let featureGatingEnable = userResolver.fg.staticFeatureGatingValue(with: .init(key: .redPacket))
        let isFeishu = ReleaseConfig.isFeishu
        let userTenant = passportUserService.user.tenant
        let isByteDancer = userTenant.isByteDancer
        // 获取权限SDK支付开关，默认打开，无权限则不显示红包入口
        let isPay = LarkPayAuthority.checkPayAuthority()
        Self.logger.info("redPacket isPay: \(isPay)")
        let redPacketEnable: Bool = featureSwitchEnable
            && isFeishu
            && (userTenant.isFeishuBrand || isByteDancer || featureGatingEnable)
            && appConfigService?.feature(for: .wallet).isOn ?? false
            && isPay
        return redPacketEnable
    }()

    private lazy var redPacket: ChatKeyboardMoreItem? = {
        guard let chatModel = self.metaModel?.chat else { return nil }
        if self.metaModel?.chat.isP2PAi == true {
            return nil
        }
        if redPacketEnable,
           !chatModel.isCrossWithKa,
           chatModel.chatterId != userResolver.userID,
           !chatModel.isSingleBot,
           !self.context.hasRootMessage,
           !chatModel.isSuper,
           !chatModel.isPrivateMode,
           !chatModel.isInMeetingTemporary {
            let item = ChatKeyboardMoreItemConfig(
                text: BundleI18n.LarkChat.Lark_Legacy_KeyboardChatOthersHongbao,
                icon: Resources.send_hongbao,
                type: .redPacket,
                tapped: { [weak self] in
                    self?.clickRedPacket()
                })
            return item
        }
        return nil
    }()

    private func clickRedPacket() {
        guard let chatModel = self.metaModel?.chat else { return }
        ChatTracker.trackSendRedPacket(isGroupChat: chatModel.type == .group)
        IMTracker.Chat.InputPlus.Click.hongbao(chatModel)
        let content = BundleI18n.LarkChat.Lark_NewContacts_NeedToAddToContactstHongbaoOneDialogContent
        /// 发红包鉴权
        let from = self.context.baseViewController()
        let body = SendRedPacketCheckAuthBody(chat: chatModel,
                                              alertContent: content,
                                              from: from)
        navigator.present(
            body: body,
            wrap: LkNavigationController.self,
            from: from,
            prepare: { $0.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen })
        self.context.foldKeyboard()
    }

    // MARK: vote
      private lazy var vote: ChatKeyboardMoreItem? = {
          let featureGatingEnable = userResolver.fg.staticFeatureGatingValue(with: .init(key: .newGroupVote))
          guard let chatModel = self.metaModel?.chat,
                    featureGatingEnable,
                    !chatModel.isCrossWithKa,
                    !chatModel.isSuper,
                    !chatModel.isSingleBot,
                    !chatModel.isPrivateMode,
                    !chatModel.isInMeetingTemporary,
                    !chatModel.isP2PAi,
                    chatModel.type == .group else { return nil }
          let item = ChatKeyboardMoreItemConfig(
              text: BundleI18n.LarkChat.Lark_Legacy_Vote,
              icon: Resources.vote,
              type: .vote,
              tapped: { [weak self] in
                  self?.clickVote()
              })
          return item
      }()

      private func clickVote() {
          let from = self.context.baseViewController()
          guard let chatModel = self.metaModel?.chat else { return }
          let body = CreateVoteBody(scene: .imChatImMessage, scopeID: chatModel.id)
          Tracker.post(TeaEvent(Homeric.IM_CHAT_INPUT_PLUS_CLICK, params: ["click": "vote", "target": "im_chat_vote_create_view"]))
          navigator.present(
              body: body,
              wrap: LkNavigationController.self,
              from: from,
              prepare: { $0.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen })
          self.context.foldKeyboard()
      }

    // MARK: sendLocation
    private lazy var sendLocation: ChatKeyboardMoreItem? = {
        if self.metaModel?.chat.isPrivateMode ?? false { return nil }
        if self.metaModel?.chat.isP2PAi == true {
            return nil
        }
        let item = ChatKeyboardMoreItemConfig(
            text: BundleI18n.LarkChat.Lark_Chat_InputwindowExpansionLocation,
            icon: Resources.location_keyboard,
            type: .location,
            tapped: { [weak self] in
                self?.clickSendLocation()
            })
        return item
    }()

    private func clickSendLocation() {
        let from = self.context.baseViewController()
        var body = SendLocationBody(psdaToken: "LARK-PSDA-ChatSendLocation-requestLocationAuthorization")
        body.sendAction = self.sendCurrentLocation
        navigator.present(
            body: body,
            wrap: LkNavigationController.self,
            from: from,
            prepare: {
                $0.modalPresentationStyle = .formSheet
            })
        self.context.foldKeyboard()
        ChatTracker.trackLocationEnter()
        IMTracker.Chat.InputPlus.Click.location(self.metaModel?.chat)
    }

    private func sendCurrentLocation(model: LocationContent, image: UIImage, mapType: String, selectedType: String) {
        guard let chatModel = self.metaModel?.chat else { return }
        /// 打点需求https://bytedance.feishu.cn/space/sheet/shtcnTF0isNVyxTNpfC4PaHLBff#dd8e91
        var chatType = ""
        switch chatModel.type {
        case .p2P:
            chatType = "single"
        case .group:
            chatType = "group"
        case .topicGroup:
            chatType = "topicGroup"
        @unknown default:
            assert(false, "new value")
            chatType = "unknown"
        }
        if chatModel.chatMode == .threadV2 {
            chatType = "group_topic"
        } else if chatType == "single", let chatterType = chatModel.chatter?.type, chatterType == .bot {
            chatType = "single_bot"
        }

        var nameType = "none"
        if !model.location.name.isEmpty {
            nameType = "building"
        } else if !model.location.description_p.isEmpty {
            nameType = "full_address"
        }

        ChatTracker.trackLocationSent(nameType: nameType, chatType: chatType, resultType: selectedType)
        ChatTracker.trackLocationMapType(type: mapType)

        self.context.sendLocation(
            parentMessage: self.context.getRootMessage(),
            screenShot: image,
            location: model
        )
    }

    // MARK: shareUserCard
    private lazy var shareUserCard: ChatKeyboardMoreItem? = {
        if self.context.hasRootMessage { return nil }
        if self.metaModel?.chat.isP2PAi == true {
            return nil
        }
        let item = ChatKeyboardMoreItemConfig(
            text: BundleI18n.LarkChat.Lark_Legacy_SendUserCard,
            icon: Resources.profile_card,
            type: .userCard,
            tapped: { [weak self] in
                self?.clickShareUserCard()
            })
        return item
    }()

    // 定时发送服务
    @ScopedInjectedLazy public var scheduleSendService: ScheduleSendService?
    @ScopedInjectedLazy var newGuideManager: NewGuideService?
    private let scheduleSendDotGuideKey = "im_chat_message_schedule_send_expand_button_dot"

    // MARK: schedule send
    private lazy var scheduleSend: ChatKeyboardMoreItem? = {
        guard self.scheduleMsgEnable else { return nil }
        guard let chat = self.metaModel?.chat else { return nil }
        if chat.isP2PAi {
            return nil
        }
        guard ScheduleSendManager.chatCanScheduleSend(chat) else { return nil }

        // 是否展示红点
        func getIsShowDotBadge() -> Bool {
            // 只有不是自己的单聊才显示引导
            guard chat.type == .p2P, chat.chatterId != userResolver.userID else { return false }
            guard let timeZoneId = chat.chatter?.timeZoneID else { return false }
            guard let scheduleSendService, scheduleSendService.checkTimezoneCanShowGuide(timezone: timeZoneId) else { return false }
            // 判断是否展示过此引导（dot）
            guard let newGuideManager, newGuideManager.checkShouldShowGuide(key: self.scheduleSendDotGuideKey) else { return false }
            return true
        }
        let isShowDotBadge = getIsShowDotBadge()
        let item = ChatKeyboardMoreItemConfig(
            text: BundleI18n.LarkChat.Lark_IM_ScheduleMessage_Scheduled_Button,
            icon: Resources.scheduleSend,
            type: .scheduleSend,
            showDotBadge: isShowDotBadge,
            tapped: { [weak self] in
                self?.clickScheduleSend()
            })
        return item
    }()

    private func clickScheduleSend() {
        // 点击时设置引导已经展示（dot）
        if let newGuideManager, newGuideManager.checkShouldShowGuide(key: self.scheduleSendDotGuideKey) {
            newGuideManager.didShowedGuide(guideKey: self.scheduleSendDotGuideKey)
        }
        if let chatModel = self.metaModel?.chat {
            IMTracker.Chat.InputPlus.Click.delayedSend(chatModel)
        }
        self.context.onMessengerKeyboardPanelScheduleSendTaped(draft: draft)
        self.draft = nil
        self.scheduleSend?.showDotBadge = false
        if let model = metaModel {
            self._moreItems = self.buildMoreItems(metaModel: model)
        }
        self.context.refreshMoreItems()
    }

    private func clickShareUserCard() {
        guard let chatModel = self.metaModel?.chat else { return }
        IMTracker.Chat.InputPlus.Click.PersonalCard(chatModel)
        ChatTracker.trackSendUserCardIconClicked()

        let chooseUserCardBlock: (String) -> Void = { [weak self] shareChatterId in
            guard let self = self else { return }
            self.context.sendUserCard(shareChatterId: shareChatterId)
        }

        let from = self.context.baseViewController()
        var body = ChatterPickerBody()
        body.selectStyle = .single(style: .callbackWithReset)
        body.title = BundleI18n.LarkChat.Lark_Legacy_SelectUserCard
        body.dataOptions = [.external]
        body.cancelCallback = {
            ChatTracker.trackSendUserCardCancel()
        }
        body.enableRelatedOrganizations = false
        body.selectedCallback = { [userResolver]controler, contactPickerResult in
            guard let controller = controler else {
                return
            }

            let alertController = LarkAlertController()
            alertController.setContent(text: BundleI18n.LarkChat.Lark_Legacy_UserCardConfirm, font: UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium))
            alertController.addCancelButton()
            alertController.addPrimaryButton(text: BundleI18n.LarkChat.Lark_Legacy_Send, dismissCompletion: { [weak controller] in
                let chatterIDs = contactPickerResult.chatterInfos.map { $0.ID }
                if let shareChatterId = chatterIDs.first, !shareChatterId.isEmpty {
                    chooseUserCardBlock(shareChatterId)
                    if let channel = contactPickerResult.extra as? String {
                        ChatTracker.trackChooseUserCardSuccess(channel: channel)
                    }
                } else {
                    ChatRouterImpl.logger.error("选人时获取不到 chatterId")
                }
                controller?.dismiss(animated: true, completion: nil)
            })
            userResolver.navigator.present(alertController, from: controller)
        }
        navigator.present(
            body: body,
            from: from,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
        )
        self.context.foldKeyboard()
    }

    // MARK: realTimeTranslate
    private var realTimeTranslate: ChatKeyboardMoreItem? {
        guard userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "im.chat.manual_open_translate")) else { return nil }
        if self.metaModel?.chat.isPrivateMode ?? false { return nil }
        let text = metaModel?.chat.typingTranslateSetting.isOpen == true ?
        BundleI18n.LarkChat.Lark_IM_TranslationAsYouType_Disable_Option : BundleI18n.LarkChat.Lark_IM_TranslationAsYouType_Enable_Option
        let item = ChatKeyboardMoreItemConfig(
            text: text,
            icon: Resources.transAssistantFilled,
            type: .realTimeTranslate,
            tapped: { [weak self] in
                self?.clickRealTimeTranslate()
            })
        return item
    }

    private func clickRealTimeTranslate() {
        guard let chat = metaModel?.chat else { return }
        IMTracker.Chat.InputPlus.Click.translationButton(chat)
        let isOpen = chat.typingTranslateSetting.isOpen
        chatAPI?.updateChat(chatId: chat.id, isRealTimeTranslate: !isOpen, realTimeTranslateLanguage: chat.typingTranslateSetting.targetLanguage)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self,
                      let metaModel = self.metaModel else { return }
                metaModel.chat.typingTranslateSetting.isOpen = !isOpen
                self._moreItems = self.buildMoreItems(metaModel: metaModel)
                self.context.refreshMoreItems()
            }, onError: { [weak self] (error) in
                /// 把服务器返回的错误显示出来
                let showMessage = BundleI18n.LarkChat.Lark_Setting_PrivacySetupFailed
                if let view = self?.context.baseViewController().viewIfLoaded {
                    UDToast.showFailure(with: showMessage, on: view, error: error)
                }
            }).disposed(by: self.disposeBag)
    }

    // MARK: - input handler
    public override var inputHandlers: [ChatKeyboardInputOpenProtocol] {
        return _inputHandlers
    }
    private var _inputHandlers: [ChatKeyboardInputOpenProtocol] = []

    public override func createInputHandlers(metaModel: ChatKeyboardMetaModel) {
        self.metaModel = metaModel
        var handers = [returnInputHandler,
                       atPickerInputHandler,
                       atUserInputHandler,
                       emojiInputHandler,
                       urlInputHandler,
                       codeInputHandler,
                       entityNumber,
                       anchorHandler]
        let resourcesCopyFG = self.context.getFeatureGating("messenger.message.copy")
        if resourcesCopyFG {
            handers.append(contentsOf: [self.videoInputHandler, self.imageInputHandler])
        } else {
            handers.append(self.imageAndVideoInputHandler)
        }
        // TODO: @wanghaidong 如果是 AI 聊天，加入 QuickActionInputHandler
        if metaModel.chat.isP2PAi {
            handers.append(quickActionInputHandler)
        }
        self._inputHandlers = handers.compactMap { $0 }
    }

    private lazy var keyboardNewStyleEnable: Bool = {
        return KeyboardDisplayStyleManager.isNewKeyboadStyle()
    }()

    // 使用通用mention组件
    private lazy var mentionOptEnable: Bool = {
        userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "messenger.message.corporate_aite_clouddocuments"))
    }()

    lazy var processor = IMAtPickerProcessor()

    private lazy var atPickerInputHandler: ChatKeyboardInputOpenProtocol = {
        let handler = AtPickerInputHandler { [weak self] (textView, range, _) in
            textView.resignFirstResponder()
            guard let self = self,
                  let chatModel = self.metaModel?.chat,
                  let textView = textView as? LarkEditTextView else { return }

            let from = self.context.baseViewController()
            let config = IMAtPickerProcessor.IMAtPickerConfig(chat: chatModel,
                                                              userResolver: self.context.userResolver,
                                                              supportAtMyAI: self.supportAtMyAI,
                                                              fromVC: from)
            self.processor.showAtPicker(config: config) { [weak textView] in
                textView?.becomeFirstResponder()
            } complete: { [weak textView] selectItems in
                // 删除已经插入的at
                textView?.selectedRange = NSRange(location: range.location + 1, length: range.length)
                textView?.deleteBackward()
                // 插入at标签
                selectItems.forEach { item in
                    switch item {
                    case .chatter(let item):
                        if item.id == self.myAIService?.defaultResource.mockID {
                            let myAIInlineService = try? self.context.userResolver.resolve(type: IMMyAIInlineService.self)
                            myAIInlineService?.openMyAIInlineMode(source: .mention)
                        } else {
                            self.context.insertAtChatter(name: item.name,
                                                         actualName: item.actualName,
                                                         id: item.id,
                                                         isOuter: item.isOuter)
                        }

                    case .doc(let url, let title, let type), .wiki(let url, let title, let type):
                        if let url = URL(string: url) {
                            self.context.insertUrl(title: title, url: url, type: type)
                        } else {
                            self.context.insertUrl(urlString: url)
                        }
                    }
                }
            }
            IMTracker.Chat.Main.Click.AtMention(chatModel, isFullScreen: false, self.context.store.getValue(for: IMTracker.Chat.Main.ChatFromWhereKey))
        }
        return NormalChatKeyboardInputOpenHandler(
            type: .atPicker,
            handler: handler
        )
    }()

    private var supportAtMyAI: Bool {
        if self.context.disableMyAI {
            return false
        }
        guard self.userResolver.fg.dynamicFeatureGatingValue(with: "im.chat.my_ai_inline"),
              let chat = self.metaModel?.chat,
              chat.supportMyAIInlineMode,
              self.myAIService?.enable.value == true,
              self.myAIService?.needOnboarding.value == false else { return false }
        return true
    }

    private lazy var returnInputHandler: ChatKeyboardInputOpenProtocol = {
        let handler = ReturnInputHandler { [weak self] (_) -> Bool in
            let returnType = (try? self?.context.resolver.resolve(assert: MessengerNormalChatKeyboardDependency.self).returnType)
            if returnType == .default {
                Self.logger.info("user did tap new line returnType default")
                return true
            } else {
                Self.logger.info("user did tap send returnType - \(returnType?.rawValue)")
                self?.context.sendInputContentAsMessage()
                return false
            }
        }
        handler.newlineFunc = { (textView) -> Bool in
            // 搜狗换行会 先输入 \r\r 然后删除一个字符 所以这里需要输入两个 \n
            Self.logger.info("user did tap send newlineFunc insert |r |r")
            textView.insertText("\n\n")
            return false
        }
        return NormalChatKeyboardInputOpenHandler(
            type: .return,
            handler: handler
        )
    }()

    private lazy var atUserInputHandler: ChatKeyboardInputOpenProtocol = {
        let handler = AtUserInputHandler(supportPasteStyle: true)
        return NormalChatKeyboardInputOpenHandler(
            type: .atUser,
            handler: handler
        )
    }()

    private lazy var quickActionInputHandler: ChatKeyboardInputOpenProtocol = {
        let handler = QuickActionInputHandler()
        return NormalChatKeyboardInputOpenHandler(
            type: .quickAction,
            handler: handler
        )
    }()

    private lazy var urlInputHandler: ChatKeyboardInputOpenProtocol? = {
        if self.metaModel?.chat.isPrivateMode ?? false { return nil }
        guard let urlPreviewAPI = try? self.context.resolver.resolve(assert: URLPreviewAPI.self) else { return nil }
        let handler = URLInputHandler(urlPreviewAPI: urlPreviewAPI)
        return NormalChatKeyboardInputOpenHandler(
            type: .url,
            handler: handler
        )
    }()

    private lazy var entityNumber: ChatKeyboardInputOpenProtocol? = {
        let handler = EntityNumInputHandler()
        return NormalChatKeyboardInputOpenHandler(
            type: .entityNum,
            handler: handler
        )
    }()

    private lazy var anchorHandler: ChatKeyboardInputOpenProtocol? = {
        let handler = AnchorInputHandler()
        return NormalChatKeyboardInputOpenHandler(
            type: .anchor,
            handler: handler
        )
    }()

    private lazy var emojiInputHandler: ChatKeyboardInputOpenProtocol = {
        let handler = EmojiInputHandler(supportFontStyle: true)
        return NormalChatKeyboardInputOpenHandler(
            type: .emoji,
            handler: handler
        )
    }()

    private lazy var imageInputHandler: ChatKeyboardInputOpenProtocol = {
        let handler = CopyImageInputHandler()
        return NormalChatKeyboardInputOpenHandler(
            type: .image,
            handler: handler
        )
    }()

    private lazy var videoInputHandler: ChatKeyboardInputOpenProtocol = {
        let handler = CopyVideoInputHandler()
        return NormalChatKeyboardInputOpenHandler(
            type: .video,
            handler: handler
        )
    }()

    private lazy var imageAndVideoInputHandler: ChatKeyboardInputOpenProtocol = {
        let handler = ImageAndVideoInputHandler()
        return NormalChatKeyboardInputOpenHandler(
            type: .imageAndVideo,
            handler: handler
        )
    }()

    private lazy var codeInputHandler: ChatKeyboardInputOpenProtocol = {
        let handler = CodeInputHandler(supportFontStyle: true)
        return NormalChatKeyboardInputOpenHandler(
            type: .code,
            handler: handler
        )
    }()
}

final class NormalChatKeyboardInputOpenHandler: ChatKeyboardInputOpenProtocol {
    let type: ChatKeyboardInputOpenType
    private let handler: TextViewInputProtocol

    init(type: ChatKeyboardInputOpenType, handler: TextViewInputProtocol) {
        self.type = type
        self.handler = handler
    }

    func register(textView: UITextView) {
        handler.register(textView: textView)
    }

    func textViewDidChange(_ textView: UITextView) {
        handler.textViewDidChange(textView)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return handler.textView(textView, shouldChangeTextIn: range, replacementText: text)
    }
}
