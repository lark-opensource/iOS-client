//
//  MessageDetailCellViewModel.swift
//  Action
//
//  Created by 赵冬 on 2019/7/18.
//

import Foundation
import LarkModel
import EEFlexiable
import AsyncComponent
import LarkCore
import LarkUIKit
import EENavigator
import LarkMessageCore
import LarkMessageBase
import LarkAccountInterface
import LarkSDKInterface
import LarkSendMessage
import LarkFeatureGating
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkExtensions
import SuiteAppConfig
import LKCommonsLogging
import RxSwift
import UniverseDesignToast
import LarkRustClient
import LarkSearchCore
import LarkContainer
import LarkStorage
import LarkOpenChat
import EEAtomic

class MessageDetailMessageCellViewModel: LarkMessageBase.MessageDetailMessageCellViewModel<MessageDetailMetaModel, MessageDetailCellModelDependency>,
                                         MessageDynamicAuthorityDelegate,
                                         MessageMenuHideProtocol {
    override var identifier: String {
        return [content.identifier, "messageDetail"].joined(separator: "-")
    }
    @PageContext.InjectedLazy var tenantUniversalSettingService: TenantUniversalSettingService?
    @PageContext.InjectedLazy private var chatSecurityControlService: ChatSecurityControlService?
    @PageContext.InjectedLazy private var messageDynamicAuthorityService: MessageDynamicAuthorityService?
    static let logger = Logger.log(MessageDetailMessageCellViewModel.self, category: "IM.module.LarkChat")

    // UI属性
    var time: String {
        var formatTime = formatCreateTime
        if message.isMultiEdited {
            formatTime += BundleI18n.LarkChat.Lark_IM_EditMessage_EditedAtTime_Hover_Mobile(formatEditedTime)
        }
        return formatTime
    }

    private var formatCreateTime: String {
        return message.createTime.lf.cacheFormat("n_message", formater: { $0.lf.formatedTime_v2() })
    }

    private var formatEditedTime: String {
        return (message.editTimeMs / 1000).lf.cacheFormat("n_editMessage", formater: { $0.lf.formatedTime_v2() })
    }

    lazy var displayName: String = {
        return getFromChatterName()
    }()

    var isFromMe: Bool {
        return context.isMe(message.fromId, chat: metaModel.getChat())
    }

    var isGroupOwner: Bool {
        return metaModel.getChat().ownerId == context.userID
    }

    var isGroupAdmin: Bool {
        return metaModel.getChat().isGroupAdmin
    }

    var messageLocalStatus: MessageLocalStatus {
        if self.message.isRecalled ||
            self.message.isDeleted ||
            self.context.isBurned(message: message) {
            return .none
        }
        if self.message.dlpState == .dlpBlock {
            return .none
        }
        switch self.message.localStatus {
        case .process:
            return .loading
        case .success, .fakeSuccess:
            return .success
        case .fail:
            return .failed
        @unknown default:
            assert(false, "new value")
            return .none
        }
    }

    lazy var title: String? = {
        return getTitle()
    }()

    ///是否正在被二次编辑
    var isEditing: Bool = false {
        didSet {
            guard isEditing != oldValue else { return }
            calculateRenderer()
        }
    }

    private(set) var isRootMessage: Bool

    var hideUserInfo: Bool {
        let chat = self.metaModel.getChat()
        return chat.type == .p2P && !isFromMe
    }

    override public init(
        metaModel: MessageDetailMetaModel,
        metaModelDependency: MessageDetailCellModelDependency,
        context: MessageDetailContext,
        contentFactory: MessageDetailMessageSubFactory,
        getContentFactory: @escaping (MessageDetailMetaModel, MessageDetailCellModelDependency) -> MessageSubFactory<MessageDetailContext>,
        subFactories: [SubType: MessageDetailMessageSubFactory],
        initBinder: (ComponentWithContext<MessageDetailContext>) -> ComponentBinder<MessageDetailContext>,
        cellLifeCycleObseverRegister: CellLifeCycleObseverRegister?,
        renderer: ASComponentRenderer? = nil
    ) {
            self.isRootMessage = metaModelDependency.config.isRootMessage
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
            if let messageDynamicAuthorityService {
                messageDynamicAuthorityService.delegate = self
            }
            super.calculateRenderer()
            for cellObsever in self.cellLifeCycleObseverRegister?.obsevers ?? [] {
                cellObsever.initialized(metaModel: self.metaModel, context: self.context)
            }
    }

    override func update(metaModel: MessageDetailMetaModel, metaModelDependency: MessageDetailCellModelDependency? = nil) {
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
        if message.isRecalled && !(content is RecalledContentViewModel) {
            self.updateContent(contentBinder: RecalledContentComponentBinder(
                viewModel: RecalledContentViewModel(
                    metaModel: metaModel,
                    metaModelDependency: MessageDetailCellModelDependency(
                        contentPadding: self.metaModelDependency.contentPadding,
                        contentPreferMaxWidth: self.metaModelDependency.contentPreferMaxWidth
                    ),
                    context: context,
                    config: RecallContentConfig()
                ),
                actionHandler: RecalledMessageActionHandler(context: context)
            ))
        } // 删除的消息
        else if message.isDeleted && !(content is DeletedContentViewModel) {
            self.updateContent(content: DeletedContentViewModel(
                metaModel: metaModel,
                metaModelDependency: MessageDetailCellModelDependency(
                    contentPadding: self.metaModelDependency.contentPadding,
                    contentPreferMaxWidth: self.metaModelDependency.contentPreferMaxWidth
                ),
                context: context
            ))
        } // 销毁的消息
        else if self.context.isBurned(message: message) && !(content is BurnedContentViewModel) {
            self.updateContent(content: BurnedContentViewModel(
                metaModel: metaModel,
                metaModelDependency: MessageDetailCellModelDependency(
                    contentPadding: self.metaModelDependency.contentPadding,
                    contentPreferMaxWidth: self.metaModelDependency.contentPreferMaxWidth
                ),
                context: context
            ))
        } else {
            self.content.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
        }
        self.displayName = getFromChatterName()
        self.title = getTitle()
        super.calculateRenderer()
    }

    func getTitle() -> String? {
        guard message.isRecalled == false else { return nil }
        var contentTitle = ""
        switch self.message.displayRule {
        case .unknownRule, .noTranslation, .withOriginal:
            guard let content = self.message.content as? PostContent, !content.isUntitledPost else {
                return nil
            }
            contentTitle = content.title
        case .onlyTranslation:
            guard let translateContent = message.translateContent as? PostContent, !translateContent.isUntitledPost else {
                return nil
            }
            contentTitle = translateContent.title
        @unknown default:
            assert(false, "new value")
            return nil
        }
        return contentTitle
    }

    func getFromChatterName() -> String {
        let chat = metaModel.getChat()
        return self.message.fromChatter?
            .displayName(chatId: chat.id, chatType: chat.type, scene: .head) ?? ""
    }

    func avatarLongPressed() {
        self.context.pageAPI?.insertAt(by: self.message.fromChatter)
    }

    func showMessageMenu(message: Message,
                                source: MessageMenuLayoutSource,
                                copyType: CopyMessageType,
                                selectConstraintKey: String?) {
        // 线上的高度
        let onlineMaxHeight: CGFloat = UIScreen.main.bounds.size.height * CGFloat(0.91)

        var maxSheetHeight: CGFloat = 0; let navigationBarSpace: CGFloat = 16
        // 如果菜单在导航控制器中子VC弹出，navigationBar层级比子VC&菜单更高，所以菜单高度过高会被navigationBar遮挡；高度预期 = 屏幕的高度 - 导航栏的最大Y - 间距
        if self.context.userResolver.fg.dynamicFeatureGatingValue(with: "im.message_detail.show_menu_optimize"),
            let navigationBar = self.context.pageAPI?.navigationController?.navigationBar,
           !navigationBar.isHidden {
            maxSheetHeight = UIScreen.main.bounds.size.height - navigationBar.frame.maxY - navigationBarSpace
            // 高度不能比线上高，否则遮挡问题依然存在
            maxSheetHeight = min(maxSheetHeight, onlineMaxHeight)
        } else {
            // 如果菜单不在导航控制器中子VC弹出，则高度保持和线上一致
            maxSheetHeight = onlineMaxHeight
        }
        let extraInfo: MessageMenuExtraInfo = .init(copyType: copyType, selectConstraintKey: selectConstraintKey, expandedSheetHeight: maxSheetHeight, moreViewMaxHeight: maxSheetHeight)
        self.context.pageContainer.resolve(MessageMenuOpenService.self)?.showMenu(message: message, source: source, extraInfo: extraInfo)
    }

    override func didSelect() {
        if self.hideSheetMenuIfNeedForMenuService(self.context.pageContainer.resolve(MessageMenuOpenService.self)) {
            return
        }
        super.didSelect()
    }

    func showMenu(_ sender: UIView,
                  location: CGPoint,
                  displayView: ((Bool) -> UIView?)?,
                  triggerGesture: UIGestureRecognizer?,
                  copyType: CopyMessageType,
                  selectConstraintKey: String?) {
        guard self.dynamicAuthorityEnum.authorityAllowed else { return }
        let source = MessageMenuLayoutSource(trigerView: sender,
                                             trigerLocation: location,
                                             displayViewBlcok: displayView,
                                             inserts: UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0))
        self.showMessageMenu(message: self.message,
                             source: source,
                             copyType: copyType,
                             selectConstraintKey: selectConstraintKey)
    }

    func resend() {
        switch message.type {
        case .media:
            guard let vc = self.context.targetVC else {
                assertionFailure("缺少路由跳转VC")
                return
            }
            try? context.resolver.resolve(assert: VideoMessageSendService.self).resendVideoMessage(message, from: vc)
        case .post:
            try? context.resolver.resolve(assert: PostSendService.self).resend(message: self.message)
        @unknown default:
            try? context.resolver.resolve(assert: SendMessageAPI.self).resendMessage(message: self.message)
        }
    }

    func insertAt() {
        if context.userID != message.fromId {
            self.context.pageAPI?.insertAt(by: message.fromChatter)
        }
    }

    override func buildDescription() -> [String: String] {
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
            "fromMe": "\(context.isMe(message.fromId, chat: metaModel.getChat()))",
            "recalled": "\(message.isRecalled)",
            "crypto": "\(false)",
            "localStatus": "\(message.localStatus)"]
    }

    // MARK: MessageDynamicAuthorityDelegate
    var dynamicAuthorityEnum: DynamicAuthorityEnum {
        return messageDynamicAuthorityService?.dynamicAuthorityEnum ?? .deny
    }
    var needAuthority: Bool {
        if metaModel.getChat().isCrypto {
            return false
        }
        return chatSecurityControlService?.getIfMessageNeedDynamicAuthority(self.message, anonymousId: self.metaModel.getChat().anonymousId) ?? false
    }
    var authorityMessage: Message? {
        return self.message
    }
    func updateUIWhenAuthorityChanged() {
        calculateRenderer()
    }
}

final class NormalChatMessageDetailMessageCellViewModel: MessageDetailMessageCellViewModel {
    var hasBorder: Bool {
        if self.message.type == .file || self.message.type == .folder {
            return true
        }
        return false
    }

    var hideContent: Bool {
        if let contentConfig = self.content.contentConfig {
            return contentConfig.hideContent
        }
        return false
    }

    var isGroupAnnouncementType: Bool {
        return (self.message.content as? PostContent)?.isGroupAnnouncement ?? false
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

    /// 翻译服务
    private lazy var translateService: NormalTranslateService? = {
        return try? self.context.resolver.resolve(assert: NormalTranslateService.self)
    }()

    /// 消息卡片转发
    private var messageCardForward: Bool {
        return self.context.getStaticFeatureGating(.messageCardForward)
    }

    /// 搜索服务
    init(
        metaModel: MessageDetailMetaModel,
        context: MessageDetailContext,
        contentFactory: MessageDetailMessageSubFactory,
        getContentFactory: @escaping (MessageDetailMetaModel, MessageDetailCellModelDependency) -> MessageSubFactory<MessageDetailContext>,
        metaModelDependency: MessageDetailCellModelDependency,
        subFactories: [SubType: MessageDetailMessageSubFactory],
        cellLifeCycleObseverRegister: CellLifeCycleObseverRegister?) {
        super.init(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: getContentFactory,
            subFactories: subFactories,
            initBinder: { contentComponent in
                return MessageDetailCellComponentBinder(message: metaModel.message, contentComponent: contentComponent, context: context)
            },
            cellLifeCycleObseverRegister: cellLifeCycleObseverRegister
        )
    }

    override func willDisplay() {
        super.willDisplay()
        let translateParam = MessageTranslateParameter(message: message,
                                                       source: .common(id: message.id),
                                                       chat: metaModel.getChat())
        self.translateService?.checkLanguageAndDisplayRule(translateParam: translateParam, isFromMe: isFromMe)
        for cellObsever in self.cellLifeCycleObseverRegister?.obsevers ?? [] {
            cellObsever.willDisplay(metaModel: self.metaModel, context: self.context)
        }
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
        guard let vc = self.context.pageAPI else {
            assertionFailure()
            return
        }
        let effectBody = TranslateEffectBody(chat: metaModel.getChat(), message: message)
        context.navigator.push(body: effectBody, from: vc)
    }
}

final class MessageDetailCellComponentBinder: ComponentBinder<MessageDetailContext> {
    var props: MessageDetailCellProps
    private var _component: MessageDetailCellComponent
    private var chatId: String

    override var component: ComponentWithContext<MessageDetailContext> {
        return _component
    }

    init(message: Message, contentComponent: ComponentWithContext<MessageDetailContext>, context: MessageDetailContext) {
        self.chatId = message.channel.id
        self.props = MessageDetailCellProps(
            contentComponent: contentComponent
        )

        _component = MessageDetailCellComponent(
            props: props,
            style: ASComponentStyle(),
            context: context
        )
        super.init()
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? NormalChatMessageDetailMessageCellViewModel else {
            assertionFailure()
            return
        }
        let chatId = self.chatId
        let userId = vm.message.fromId
        props.avatarTapped = { [weak vm] in
            guard let vm, let targetVC = vm.context.pageAPI else { return }
            let body = PersonCardBody(chatterId: userId,
                                      chatId: chatId,
                                      source: .chat)
            vm.context.navigator.presentOrPush(
                body: body,
                wrap: LkNavigationController.self,
                from: targetVC,
                prepareForPresent: { vc in
                    vc.modalPresentationStyle = .formSheet
                })
        }
        props.menuTapped = { [weak vm] (view) in
            vm?.showMenu(view, location: CGPoint(x: 20, y: 20), displayView: nil, triggerGesture: nil, copyType: .message, selectConstraintKey: nil)
        }
        props.avatarLongPressed = { [weak vm] in
            vm?.insertAt()
        }
        props.name = vm.displayName
        props.time = vm.time
        props.messageType = vm.message.type
        props.messageLocalStatus = vm.messageLocalStatus
        let contentComponent = vm.contentComponent
        contentComponent._style.display = vm.hideContent ? .none : .flex
        props.contentComponent = contentComponent
        props.hasBorder = vm.hasBorder
        props.didTappedLocalStatus = { [weak vm] (_, status) in
            guard status == .failed else {
                return
            }
            vm?.resend()
        }
        props.title = vm.title
        // 翻译状态
        props.translateStatus = vm.message.translateState
        props.displayRule = vm.message.displayRule

        // 翻译icon点击事件
        props.translateTapHandler = { [weak vm] in
            vm?.translateTapHandler()
        }
        // 被其他人自动翻译
        props.isAutoTranslatedByReceiver = vm.message.isAutoTranslatedByReceiver
        // 被其他人自动翻译icon点击事件
        props.autoTranslateTapHandler = { [weak vm] in
            vm?.autoTranslateTapHandler()
        }
        props.isFromMe = vm.isFromMe
        props.isDecryptoFail = vm.message.isDecryptoFail
        props.isRootMessage = vm.isRootMessage
        props.fromChatter = vm.message.fromChatter
        props.subComponents = vm.getSubComponents()
        // 是否展示翻译 icon
        let mainLanguage = KVPublic.AI.mainLanguage.value()
        let messageCharThreshold = KVPublic.AI.messageCharThreshold.value()
        var canShowTranslateIcon: Bool {
            guard AIFeatureGating.translationOptimization.isEnabled else { return false }
            if mainLanguage.isEmpty { return false }
            if vm.message.messageLanguage.isEmpty { return false }
            if vm.message.messageLanguage == "not_lang" { return false }
            if vm.message.type == .audio { return false }
            if messageCharThreshold <= 0 { return false }
            if vm.message.characterLength <= 0 { return false }
            let isMainLanguage = mainLanguage == vm.message.messageLanguage
            let isBeyondCharThreshold = vm.message.characterLength >= messageCharThreshold
            let isAutoTranslate = vm.metaModel.getChat().isAutoTranslate
            return !vm.message.isRecalled && !vm.isFromMe && !isMainLanguage && isBeyondCharThreshold && !isAutoTranslate
        }

        props.canShowTranslateIcon = canShowTranslateIcon
        //是否正在被二次编辑
        props.isEditing = vm.isEditing
        props.translateTrackingInfo = makeTranslateTrackInfo(with: vm)
        props.dynamicAuthorityEnum = vm.dynamicAuthorityEnum

        _component.props = props
    }

    private func makeTranslateTrackInfo(with viewModel: NormalChatMessageDetailMessageCellViewModel) -> [String: Any] {
        var trackInfo = [String: Any]()
        trackInfo["chat_id"] = viewModel.metaModel.getChat().id
        trackInfo["chat_type"] = viewModel.chatTypeForTracking
        trackInfo["msg_id"] = viewModel.message.id
        trackInfo["message_language"] = viewModel.message.messageLanguage
        return trackInfo
    }
}
