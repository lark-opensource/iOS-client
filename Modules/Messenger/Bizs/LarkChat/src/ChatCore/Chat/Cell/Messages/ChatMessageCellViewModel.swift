//
//  ChatMessageCellViewModel.swift
//  LarkNewChat
//
//  Created by zc09v on 2019/3/31.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import EEFlexiable
import AsyncComponent
import LarkMessageCore
import LarkTag
import LarkUIKit
import LarkCore
import RxRelay
import LarkMessageBase
import EENavigator
import LarkNavigator
import LarkFeatureGating
import LarkAccountInterface
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkExtensions
import LarkSDKInterface
import SuiteAppConfig
import LarkBizAvatar
import LarkAlertController
import LKCommonsLogging
import LarkContainer
import LKCommonsTracker
import Homeric
import UniverseDesignToast
import LarkRustClient
import LarkSearchCore
import UniverseDesignColor
import LarkSetting
import LarkOpenChat

private let lastShowTimeMessageId = "lastShowTimeMessageId"

class ChatMessageCellViewModel: LarkMessageBase.ChatMessageCellViewModel<ChatMessageMetaModel, ChatCellMetaModelDependency>, HasCellConfig, MessageMenuHideProtocol {
    static let logger = Logger.log(ChatMessageCellViewModel.self, category: "Chat.ChatMessageCellViewModel")
    private lazy var readStatesProtectEnable: Bool = context.getStaticFeatureGating("chat.message.readstate_protect")
    private lazy var _identifier: String = {
        return [content.identifier, "message"].joined(separator: "-")
    }()
    @PageContext.InjectedLazy var tenantUniversalSettingService: TenantUniversalSettingService?
    @PageContext.InjectedLazy var chatSecurityControlService: ChatSecurityControlService?

    /// 服务端时间服务
    private lazy var serverNTPTimeService: ServerNTPTimeService? = {
        return try? self.context.resolver.resolve(assert: ServerNTPTimeService.self)
    }()

    override var identifier: String {
        return _identifier
    }

    var cellConfig: ChatCellConfig {
        return self.config
    }

    var isGroupAnnouncementType: Bool {
        return (self.message.content as? PostContent)?.isGroupAnnouncement ?? false
    }

    var isGroupOwner: Bool {
        return metaModel.getChat().ownerId == context.userID
    }

    var isGroupAdmin: Bool {
        return metaModel.getChat().isGroupAdmin
    }

    var bubbleStyle: BubbleStyle {
        if self.message.showInThreadModeStyle {
            return .thread
        }
        return .normal
    }

    // UI属性

    /// 当前cell是否被选中
    var checked: Bool = false {
        didSet {
            guard checked != oldValue else { return }
            calculateRenderer()
        }
    }
    /// 当前进入多选模式
    var inSelectMode: Bool = false {
        didSet {
            guard inSelectMode != oldValue else { return }
            calculateRenderer()
        }
    }

    ///高亮显示
    var isHightlight: Bool = false {
        didSet {
            guard isHightlight != oldValue else { return }
            calculateRenderer()
        }
    }

    ///是否正在被二次编辑
    var isEditing: Bool = false {
        didSet {
            guard isEditing != oldValue else { return }
            calculateRenderer()
        }
    }

    /// 是否应该显示checkbox
    var showCheckBox: Bool {
        guard self.dynamicAuthorityAllowed else { return false }
        guard self.message.dlpState != .dlpBlock else { return false}
        let supportMutiSelect = content.contentConfig?.supportMutiSelect ?? false
        return inSelectMode && supportMutiSelect
    }

    var dynamicAuthorityAllowed: Bool {
        return chatSecurityControlService?.getDynamicAuthorityFromCache(event: .receive,
                                                                       message: self.message,
                                                                       anonymousId: metaModel.getChat().anonymousId).authorityAllowed
            ?? false
    }

    var chatComponentTheme: ChatComponentTheme {
        let scene = self.context.pageAPI?.getChatThemeScene() ?? .defaultScene
        return ChatComponentThemeManager.getComponentTheme(scene: scene)
    }

    var hasTime: Bool = false {
        didSet {
            guard hasTime != oldValue else { return }
            calculateRenderer()
        }
    }

    var isFromMe: Bool {
        return context.isMe(message.fromId, chat: metaModel.getChat())
    }

    var config: ChatCellConfig

    /// 针对系统消息，fromChatter需要特殊处理
    var fromChatter: Chatter? {
        return (message.content as? SystemContent)?.triggerUser ?? message.fromChatter
    }

    var formatTime: String {
        var formatTime = formatCreateTime
        if message.isMultiEdited {
            formatTime += BundleI18n.LarkChat.Lark_IM_EditMessage_EditedAtTime_Hover_Mobile(formatEditedTime)
        }
        return formatTime
    }

    var hideUserInfo: Bool {
        let chat = self.metaModel.getChat()
        return chat.type == .p2P && !isFromMe
    }

    private var formatCreateTime: String {
        return message.createTime.lf.cacheFormat("message", formater: {
            $0.lf.formatedTime_v2(accurateToSecond: true)
        })
    }

    private var formatEditedTime: String {
        return (message.editTimeMs / 1000).lf.cacheFormat("editMessage", formater: {
            $0.lf.formatedTime_v2(accurateToSecond: true)
        })
    }

    var contentPreferMaxWidth: CGFloat {
        return self.metaModelDependency.getContentPreferMaxWidth(message)
    }

    override public init(
        metaModel: ChatMessageMetaModel,
        metaModelDependency: ChatCellMetaModelDependency,
        context: ChatContext,
        contentFactory: ChatMessageSubFactory,
        getContentFactory: @escaping (ChatMessageMetaModel, ChatCellMetaModelDependency) -> MessageSubFactory<ChatContext>,
        subFactories: [SubType: ChatMessageSubFactory],
        initBinder: (ComponentWithContext<ChatContext>) -> ComponentBinder<ChatContext>,
        cellLifeCycleObseverRegister: CellLifeCycleObseverRegister?,
        renderer: ASComponentRenderer? = nil
    ) {
        self.config = metaModelDependency.config
        super.init(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: getContentFactory,
            subFactories: subFactories,
            initBinder: initBinder,
            cellLifeCycleObseverRegister: cellLifeCycleObseverRegister,
            renderer: renderer
        )
        for cellObsever in self.cellLifeCycleObseverRegister?.obsevers ?? [] {
            cellObsever.initialized(metaModel: self.metaModel, context: self.context)
        }
    }

    override func update(metaModel: ChatMessageMetaModel, metaModelDependency: ChatCellMetaModelDependency? = nil) {
        self.fixUnreadState(metaModel: metaModel)
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
    }

    private func fixUnreadState(metaModel: ChatMessageMetaModel) {
        guard readStatesProtectEnable else { return }
        //数据可能存在时许问题，目前消息没有版本号，暂时只做已读未读状态保护
        let currentMessage = self.message
        let newMessage = metaModel.message
        //前提是总数相同的情况下，保证已读数不会变小
        if currentMessage.readCount + currentMessage.unreadCount == newMessage.readCount + newMessage.unreadCount,
           currentMessage.readCount > newMessage.readCount {
            Self.logger.error("""
                chatTrace fixUnreadState exception \(self.metaModel.getChat().id)
                \(newMessage.unreadCount) \(newMessage.readCount)
                \(currentMessage.message.unreadCount) \(currentMessage.message.readCount)
                """)
            newMessage.readCount = currentMessage.readCount
            newMessage.unreadCount = currentMessage.unreadCount
            newMessage.readAtChatterIds = currentMessage.readAtChatterIds
        }
    }

    func update(config: ChatCellConfig) {
        self.config = config
        self.calculateRenderer()
    }

    func onAvatarTapped() {
        guard let chatter = fromChatter,
              chatter.profileEnabled,
              let targetVC = self.context.pageAPI else { return }
        if self.context.scene == .newChat || self.context.scene == .threadChat {
            IMTracker.Chat.Main.Click.Msg.Icon(self.metaModel.getChat(), self.message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
            if self.context.scene == .newChat {
                IMTracker.Chat.Main.Click.Msg.AvatarMedal(chatter.id,
                                                          chatter.medalKey,
                                                          context.trackParams[PageContext.TrackKey.sceneKey] as? String)
            }
        } else if self.context.scene == .threadDetail || self.context.scene == .replyInThread {
            ChannelTracker.TopicDetail.Click.Msg.Icon(self.metaModel.getChat(), self.message)
        }

        let body = PersonCardBody(chatterId: chatter.id,
                                  chatId: metaModel.getChat().id,
                                  fromWhere: .chat,
                                  source: .chat)
        context.navigator.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: targetVC,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }

    func avatarLongPressed() {
        self.context.pageAPI?.insertAt(by: self.message.fromChatter)
    }

    public func showMessageMenu(message: Message,
                                source: MessageMenuLayoutSource,
                                copyType: CopyMessageType,
                                selectConstraintKey: String?) {
        self.context.pageContainer.resolve(MessageMenuOpenService.self)?.showMenu(message: message,
                                                                             source: source,
                                                                             extraInfo: .init(copyType: copyType, selectConstraintKey: selectConstraintKey))
    }

    func showMenu(_ sender: UIView,
                  location: CGPoint,
                  displayView: ((Bool) -> UIView?)?,
                  triggerGesture: UIGestureRecognizer?,
                  copyType: CopyMessageType,
                  selectConstraintKey: String?) {
        // 文件权限管控
        guard self.dynamicAuthorityAllowed else { return }
        // 如果是折叠消息(消息聚合需求)，屏蔽Menu的操作
        if message.isDecryptoFail { return }
        if message.isFoldRootMessage,
           let foldContent = self.content as? FoldMessageContentViewModel {
            foldContent.showFoldMessageMenu(targetView: sender)
            return
        }

        let source = MessageMenuLayoutSource(trigerView: sender,
                                             trigerLocation: location,
                                             displayViewBlcok: displayView,
                                             inserts: UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0))
        self.showMessageMenu(message: message,
                             source: source,
                             copyType: copyType,
                             selectConstraintKey: selectConstraintKey)
    }

    func getDisplayName(chatter: Chatter, chat: Chat, scene: GetChatterDisplayNameScene) -> String {
        return context.getDisplayName(chatter: chatter, chat: chat, scene: scene)
    }

    func nameTags(for chatter: Chatter?) -> [Tag] {
        guard let chatter = chatter, self.config.isSingle,
            let passportUserService = try? context.resolver.resolve(assert: PassportUserService.self)
        else { return [] }

        var result: [TagType] = []
        let tenantId = passportUserService.user.tenant.tenantID
        let isShowBotIcon = (chatter.type == .bot && !chatter.withBotTag.isEmpty)

        if chatter.workStatus.status == .onLeave, chatter.tenantId == tenantId {
            result = !chatter.isFrozen ? [.onLeave] : []
        } else {
            result = isShowBotIcon ? [.robot] : []
        }
        if chatter.isSpecialFocus {
            result.append(.specialFocus)
        }
        // 当用户没有离职的时候 才需要添加冻结标签
        if chatter.isFrozen, !chatter.isResigned {
            result.append(.isFrozen)
        }

        /// 判断勿扰模式
        if serverNTPTimeService?.afterThatServerTime(time: chatter.doNotDisturbEndTime) == true {
            result.append(.doNotDisturb)
        }
        var resultTags = result.map({ Tag(type: $0) })
        resultTags.append(contentsOf: chatter.eduTags)
        return resultTags
    }

    func toggleTime() {
        let chatPageAPI = context.chatPageAPI
        guard let store = context.pageContainer.resolve(KVStoreService.self) else { return }
        let key = lastShowTimeMessageId
        if let lastShowTimeMessageId: String = store.getValue(for: key) {
            if self.message.id == lastShowTimeMessageId {
                self.hasTime = !self.hasTime
                let value = self.hasTime ? self.message.id : nil
                store.setValue(value, for: key)
                chatPageAPI?.reloadRows(current: self.message.id, others: [])
            } else {
                self.hasTime = true
                store.setValue(self.message.id, for: key)
                // swiftlint:disable first_where
                if let lastVM = context.dataSourceAPI?.filter({ (vm) -> Bool in
                    return vm.content.message.id == lastShowTimeMessageId
                }).first as? ChatMessageCellViewModel {
                    lastVM.hasTime = false
                }
                // swiftlint:enable first_where
                chatPageAPI?.reloadRows(current: self.message.id, others: [lastShowTimeMessageId])
            }
        } else {
            self.hasTime = true
            store.setValue(self.message.id, for: key)
            chatPageAPI?.reloadRows(current: self.message.id, others: [])
        }
    }

    public override func buildDescription() -> [String: String] {
        let isPin = message.pinChatter != nil
        return ["id": "\(message.id)",
            "cid": "\(message.cid)",
            "type": "\(message.type)",
            "channelId": "\(message.channel.id)",
            "channelType": "\(message.channel.type)",
            "rootId": "\(message.rootId)",
            "parentId": "\(message.parentId)",
            "position": "\(message.position)",
            "urgent": "\(message.isUrgent)",
            "pin": "\(isPin)",
            "burned": "\(context.isBurned(message: message))",
            "fromMe": "\(isFromMe)",
            "recalled": "\(message.isRecalled)",
            "localStatus": "\(message.localStatus)",
            "readCount": "\(message.readCount)",
            "unReadCount": "\(message.unreadCount)",
            "displaymode": "\(message.displayInThreadMode)",
            "isSecretChatDecryptedFailed": "\(message.isSecretChatDecryptedFailed)"]
    }
}

final class NormalChatMessageCellViewModel: ChatMessageCellViewModel {
    /// 翻译服务
    private lazy var translateService: NormalTranslateService? = {
        return try? self.context.resolver.resolve(assert: NormalTranslateService.self)
    }()

    var flagIconMargin: CGFloat {
        // 语音消息有小红点，图标位置单独处理
        guard let audioContent = self.content as? AudioContentViewModel else {
            return 6.0
        }
        return audioContent.hasRedDot ? 19.0 : 6.0
    }

    /// translate Tracking
    var chatTypeForTracking: String {
        if metaModel.getChat().chatMode == .threadV2 {
            return "topic"
        } else if metaModel.getChat().type == .group {
            return "group"
        } else {
            return "single"
        }
    }

    // Doc 预加载服务
    private lazy var preloadDocDependency: DocPreviewViewModelContextDependency? = {
        return try? self.context.resolver.resolve(assert: DocPreviewViewModelContextDependency.self)
    }()

    private var preloadedDocURLs: [String] = []

    var hasMessageStatus: Bool {
        let chatWithBot = metaModel.getChat().chatter?.type == .bot
        // 有消息状态首先是我发的消息，如果是和机器人的消息发送成功了也不显示
        return config.hasStatus && (isFromMe && !(chatWithBot && message.localStatus == .success))
    }

    var nameTag: [Tag] = []
    // 消息thread需求
    @PageContext.InjectedLazy private var replyInThreadConfig: ReplyInThreadConfigService?
    let avatarLayout: AvatarLayout
    lazy var threadReplyBubbleOptimize: Bool = context.getStaticFeatureGating("im.message.thread_reply_bubble_optimize")

    init(metaModel: ChatMessageMetaModel,
         context: ChatContext,
         contentFactory: ChatMessageSubFactory,
         getContentFactory: @escaping (ChatMessageMetaModel, ChatCellMetaModelDependency) -> MessageSubFactory<ChatContext>,
         subfactories: [SubType: ChatMessageSubFactory],
         metaModelDependency: ChatCellMetaModelDependency,
         cellLifeCycleObseverRegister: CellLifeCycleObseverRegister?) {
        let avartarLayout: AvatarLayout
        if context.dataSourceAPI?.supportAvatarLeftRightLayout ?? false,
           context.isMe(metaModel.message.fromId, chat: metaModel.getChat()) {
            avartarLayout = .right
        } else {
            avartarLayout = .left
        }
        self.avatarLayout = avartarLayout
        super.init(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: getContentFactory,
            subFactories: subfactories,
            initBinder: { contentComponent in
                return NewChatMessageCellComponentBinder(context: context, contentComponent: contentComponent)
            },
            cellLifeCycleObseverRegister: cellLifeCycleObseverRegister
        )
        self.nameTag = nameTags(for: self.fromChatter)
        super.calculateRenderer()

        context.chatPageAPI?.inSelectMode
            .subscribe(onNext: { [weak self] (inSelectMode) in
                guard let self = self else { return }
                self.inSelectMode = inSelectMode
                if inSelectMode, (context.chatPageAPI?.selectedMessages.value ?? []).contains(where: { $0.id == self.message.id }) {
                    self.checked = true
                }
            })
            .disposed(by: self.disposeBag)
    }

    override func willDisplay() {
        super.willDisplay()
        /// 折叠的消息不需要关注翻译，不支持翻译
        if message.foldId <= 0 {
            let translateParam = MessageTranslateParameter(message: message,
                                                           source: .common(id: message.id),
                                                           chat: metaModel.getChat())
            self.translateService?.checkLanguageAndDisplayRule(translateParam: translateParam, isFromMe: isFromMe)
        }
        trackAbbreviation(willDisplay: true)
        self.preloadContentIfNeededFor(message)
        for cellObsever in self.cellLifeCycleObseverRegister?.obsevers ?? [] {
            cellObsever.willDisplay(metaModel: self.metaModel, context: self.context)
        }
    }

    override func didEndDisplay() {
        super.didEndDisplay()
        trackAbbreviation(willDisplay: false)
    }

    private var abbrDisplayingStatus: [String: Bool] = [:]
    private func trackAbbreviation(willDisplay: Bool) {
        func getAbbrDisplayingStatus(willDisplay: Bool) -> Bool {
            let displaying = abbrDisplayingStatus[message.id] ?? false
            abbrDisplayingStatus[message.id] = willDisplay
            return displaying
        }
        guard !getAbbrDisplayingStatus(willDisplay: willDisplay) else { return }
        if let subViewModel = content as? TextPostContentViewModel,
           let abbreviation = subViewModel.originContent.abbreviation {
            var abbrIds = [String]()
            for (_, abbreInfo) in abbreviation {
                let refs = abbreInfo.refs ?? []
                for ref in refs {
                    let id = ref.baikeEntityMeta.id
                    abbrIds.append(id)
                }
            }
            for abbrId in abbrIds {
                let params: [String: Any] = [
                    "chat_id": message.chatID,
                    "message_id": message.id,
                    "abbr_id": abbrId
                ]
                Tracker.post(TeaEvent(Homeric.ASL_ABBR_IM_VIEW, params: params))
            }
        }

    }

    // 针对消息卡片中出现的 doc 链接进行预加载，提高秒开率
    private func preloadContentIfNeededFor(_ message: Message) {
        if message.type == .card, let content = message.content as? CardContent {
            // 文档预加载
            let richText = content.richText
            for element in richText.elements.values {
                let text: String = {
                    switch element.tag {
                    case .a:
                        return element.property.anchor.iosHref
                    case .link:
                        return element.property.link.url
                    @unknown default:
                        return ""
                    }
                }()
                guard let url = URL(string: text) else { continue }
                let urlString = url.absoluteString

                if !preloadedDocURLs.contains(urlString) {
                    preloadDocDependency?.preloadDocFeed(urlString, from: chatTypeForTracking + "_message_card")
                }
            }
        }
    }

    override func update(metaModel: ChatMessageMetaModel, metaModelDependency: ChatCellMetaModelDependency? = nil) {
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
        if let metaModelDependency = metaModelDependency {
            self.config = metaModelDependency.config
        }
        // TODO: 后续把判断逻辑抽离
        if message.isFoldRootMessage {
            if !(content is FoldMessageContentViewModel) {
                let vm = FoldMessageContentViewModel(
                    metaModel: metaModel,
                    metaModelDependency: metaModelDependency ?? ChatCellMetaModelDependency(
                        contentPadding: self.metaModelDependency.contentPadding,
                        contentPreferMaxWidth: self.metaModelDependency.contentPreferMaxWidth
                    ),
                    context: context
                )
                self.updateContent(content: vm)
            } else {
                self.updateContent(
                    metaModel: metaModel,
                    metaModelDependency: metaModelDependency ?? ChatCellMetaModelDependency(
                        contentPadding: self.metaModelDependency.contentPadding,
                        contentPreferMaxWidth: self.metaModelDependency.contentPreferMaxWidth
                    )
                )
            }
        } else if message.isRecalled && !(content is RecalledContentViewModel) {
            self.updateContent(contentBinder: RecalledContentComponentBinder(
                viewModel: RecalledContentViewModel<ChatMessageMetaModel, ChatCellMetaModelDependency, ChatContext>(
                    metaModel: metaModel,
                    metaModelDependency: ChatCellMetaModelDependency(
                        contentPadding: self.metaModelDependency.contentPadding,
                        contentPreferMaxWidth: self.metaModelDependency.contentPreferMaxWidth
                    ),
                    context: context
                ),
                actionHandler: RecalledMessageActionHandler(context: context)
            ))
        } else {
            self.updateContent(metaModel: metaModel, metaModelDependency: metaModelDependency)
        }
        self.nameTag = nameTags(for: message.fromChatter)
        self.calculateRenderer()
    }

    /// 显示原文、收起译文
    func translateTapHandler() {
        guard let vc = self.context.pageAPI else {
            assertionFailure()
            return
        }
        let translateParam = MessageTranslateParameter(message: message,
                                                       source: MessageSource.common(id: message.id),
                                                       chat: metaModel.getChat())
        self.translateService?.translateMessage(translateParam: translateParam, from: vc)
    }

    /// 消息被其他人自动翻译icon点击事件
    func autoTranslateTapHandler() {
        guard let controller = context.pageAPI else {
            assertionFailure()
            return
        }
        let effectBody = TranslateEffectBody(
            chat: metaModel.getChat(),
            message: message
        )
        context.navigator.push(body: effectBody, from: controller)
    }

    override func didSelect() {
        if self.hideSheetMenuIfNeedForMenuService(self.context.pageContainer.resolve(MessageMenuOpenService.self)) {
            return
        }
        if self.inSelectMode {
            self.toggleChecked()
        } else if message.localStatus == .success {
            self.toggleTime()
        }
        super.didSelect()
    }

    override func avatarLongPressed() {
        // 如果是长按了自己的MyAI，则不执行后续操作
        if self.message.fromChatter?.type == .ai { return }

        super.avatarLongPressed()
    }

    private func toggleChecked() {
        guard let chatSecurityControlService, chatSecurityControlService.getDynamicAuthorityFromCache(event: .receive,
                                                                      message: self.message,
                                                                      anonymousId: metaModel.getChat().anonymousId).authorityAllowed else { return }
        guard content.contentConfig?.supportMutiSelect ?? false &&
            content.contentConfig?.selectedEnable ?? false else { return }
        guard let chatPageAPI = self.context.chatPageAPI else { return }

        /// 超过选择数量上限
        if !self.checked, chatPageAPI.selectedMessages.value.count >= MultiSelectInfo.maxSelectedMessageLimitCount {
            let alertController = LarkAlertController()
            alertController.setContent(text: BundleI18n.LarkChat.Lark_Chat_SelectMaximumMessagesToast)
            alertController.addPrimaryButton(text: BundleI18n.LarkChat.Lark_Group_RevokeIKnow)
            chatPageAPI.present(alertController, animated: true)
            return
        }

        // MyAI主会场里的分会场消息不支持多选，不然用户就可以同时选主会场 + 分会场消息，造成Bug：
        // 合并转发：顺序会乱；逐条转发：之前ReplyInThread就不支持逐条转发；复制消息链接：需要服务端加接口
        if self.metaModel.getChat().isP2PAi, self.message.aiChatModeID > 0 {
            UDToast.showTips(with: BundleI18n.AI.MyAI_IM_CollabRecordsCantMultiselect_Toast, on: chatPageAPI.view)
            return
        }

        // 没回复完成的消息不允许选中
        if self.message.streamStatus == .streamTransport || self.message.streamStatus == .streamPrepare {
            UDToast.showTips(with: BundleI18n.AI.MyAI_IM_GeneratingResponseSelectLater_Toast, on: chatPageAPI.view)
            return
        }

        self.checked = !self.checked
        self.context.chatPageAPI?.toggleSelectedMessage(by: message.id)
    }

    func toReplyInThread() {
        guard self.message.showInThreadModeStyle else {
            return
        }

        if let menuOpenService = self.context.pageContainer.resolve(MessageMenuOpenService.self),
           menuOpenService.hasDisplayMenu,
           menuOpenService.isSheetMenu {
            return
        }

        let body = ReplyInThreadByModelBody(message: message,
                                            chat: metaModel.getChat(),
                                            loadType: .unread,
                                            position: nil,
                                            sourceType: .chat,
                                            chatFromWhere: ChatFromWhere(fromValue: context.trackParams[PageContext.TrackKey.sceneKey] as? String) ?? .ignored)
        context.navigator(type: .push, body: body, params: nil)
    }
}

// MARK: - NewChatMessageCellComponent
extension NormalChatMessageCellViewModel {
    var cellComponentBgColor: UIColor {
        // 背景颜色优先级：pin/标记 > 二次编辑 > 选中态 > chatComponentTheme
        if oneOfSubComponentsDisplay([.pin, .chatPin, .flag]) {
            // backgroundColor is yellow when cell was pined
            return UDMessageColorTheme.imMessageBgPin
        } else if isEditing {
            // backgroundColor is yellow when cell was editing
            return UDMessageColorTheme.imMessageBgEditing
        } else if checked {
            // backgroundColor is gray when cell is checked
            return UIColor.ud.staticBlack.withAlphaComponent(0.02) & UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.05)
        } else if chatComponentTheme.isDefaultScene {
            return message.isEphemeral ? (UIColor.ud.staticBlack.withAlphaComponent(0.02) & UIColor.ud.staticWhite5) : (UIColor.ud.bgBody & UIColor.ud.bgBase)
        } else {
            // backgroundColor is nil when nothing
            return .clear
        }
    }

    // 是否展示头像
    var showAvatar: Bool {
        // 吸附消息 & 折叠消息 & 选中状态时，不展示头像
        if !config.isSingle || message.isFoldRootMessage || inSelectMode {
            return false
        }
        return true
    }

    // 是否展示Top区域（临时消息）
    var showTop: Bool {
        return config.isSingle && message.isEphemeral
    }

    // 是否显示Header区域
    var showHeader: Bool {
        return config.isSingle && config.hasHeader && !message.isFoldRootMessage && avatarLayout == .left
    }

    // 是否展示Time
    var showTime: Bool {
        return hasTime && !message.isFoldRootMessage
    }

    var highlightBgColor: UIColor {
        return isHightlight ? UDMessageColorTheme.imMessageBgLocation : UIColor.clear
    }

    var showHighlightBlur: Bool {
        return oneOfSubComponentsDisplay([.pin, .chatPin, .flag])
    }

    var highlightBlurColor: UIColor {
        return chatComponentTheme.pinHighlightColor
    }

    // 是否是文件卡片（文件消息且渲染出了卡片）
    var isFileCard: Bool {
        return message.type == .file && getSubComponent(subType: .tcPreview) != nil
    }

    var bubbleConfig: BubbleViewConfig {
        return BubbleViewConfig(
            changeTopCorner: config.changeTopCorner,
            changeBottomCorner: config.changeBottomCorner,
            changeRaiusReverse: (avatarLayout == .right),
            bubbleStyle: bubbleStyle,
            strokeColor: bubbleStrokeColor,
            fillColor: bubbleFillColor,
            strokeWidth: bubbleStrokeWidth
        )
    }

    private var bubbleStrokeColor: UIColor {
        if bubbleStyle == .normal {
            let contentConfig = content.contentConfig
            if contentConfig?.hasBorder ?? false {
                let borderStyle = contentConfig?.borderStyle ?? .card
                switch borderStyle {
                case .card: return UDMessageColorTheme.imMessageCardBorder
                case .custom(let strokeColor, _): return strokeColor
                case .image, .other: return UIColor.ud.lineBorderCard
                }
            } else {
                return UIColor.clear
            }
        } else if message.displayInThreadMode || !threadReplyBubbleOptimize {
            return UIColor.ud.lineBorderCard
        } else {
            // 话题回复，去掉边框
            return UIColor.clear
        }
    }

    private var bubbleFillColor: UIColor {
        if bubbleStyle == .normal {
            let contentConfig = content.contentConfig
            // 有边框则设置背景透明
            if contentConfig?.hasBorder ?? false {
                return UIColor.clear
            } else {
                // 气泡背景样式，white为自己发的/分享日常/分享群卡片
                let contentBackgroundStyle = contentConfig?.backgroundStyle ?? (isFromMe ? .white : .gray)
                switch contentBackgroundStyle {
                case .white:
                    // white为蓝色的背景
                    return context.getColor(for: .Message_Bubble_Background, type: .mine)
                case .gray:
                    // gray为灰色的背景
                    return context.getColor(for: .Message_Bubble_Background, type: .other)
                case .clear:
                    return UIColor.clear
                }
            }
        } else if message.displayInThreadMode || !threadReplyBubbleOptimize {
            // 话题模式创建的话题，设置白色背景
            return UIColor.ud.bgBody
        } else {
            // 话题回复，需要设置背景
            return context.getColor(for: .Message_Bubble_Background, type: isFromMe ? .mine : .other)
        }
    }

    private var bubbleStrokeWidth: CGFloat {
        let contentConfig = content.contentConfig
        if bubbleStyle == .normal, (contentConfig?.hasBorder ?? false), contentConfig?.borderStyle == .image {
            return 1 / UIScreen.main.scale
        }
        return 1
    }

    var allSubComponents: [SubType: ComponentWithContext<ChatContext>] {
        if message.isFoldRootMessage {
            return [:]
        }
        return getSubComponents()
    }

    func oneOfSubComponentsDisplay(_ types: [SubType]) -> Bool {
        // 折叠消息没有子组件
        guard !message.isFoldRootMessage else { return false }
        return types.contains(where: { getSubComponent(subType: $0)?._style.display == .flex })
    }
}
