//
//  ThreadSystemCellViewModel.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/1/29.
//

import UIKit
import Foundation
import LarkModel
import EEFlexiable
import AsyncComponent
import RichLabel
import LarkCore
import EENavigator
import LarkMessageBase
import RxSwift
import LKCommonsLogging
import UniverseDesignToast
import LarkUIKit
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import Homeric
import LKCommonsTracker
import LarkContainer
import RustPB
import ServerPB

public protocol SystemContentContext: PageContext, SystemCellComponentContext {
    var maxCellWidth: CGFloat { get }
    var currentChatterID: String { get }
    @available(*, deprecated, message: "this function could't judge anonymous scene, the best is to use new isMe with metaModel parameter")
    func isMe(_ chatterId: String) -> Bool
    func isMe(_ chatterID: String, chat: Chat) -> Bool
    var withdrawAddGroupMemberService: WithdrawAddGroupMemberService? { get }

    // 获取被At的群外的人
    func getAtOuterChatterIDs(_ messageID: String) -> Observable<[String]>

    // 检查已经在群里的人
    func checkIsChattersInChat(_ chatterIDS: [String], chatId: String) -> Observable<[String]>

    func getActionURL(_ messageID: String) -> Observable<String>

    func sendLarkCommandPayload(cmd: Int32, payload: Data) -> Observable<Void>
    /// 拨打电话
    func callContacts(_ chatterId: String)

    func showGuide(key: String)

    func getChatThemeScene() -> ChatThemeScene

    var chatAPI: ChatAPI? { get }
}

extension PageContext: SystemContentContext {
    public var chatAPI: ChatAPI? {
        return try? resolver.resolve(assert: ChatAPI.self, cache: true)
    }

    public var currentChatterID: String { return userID }

    var messageAPI: MessageAPI? {
        return try? resolver.resolve(assert: MessageAPI.self, cache: true)
    }

    public var withdrawAddGroupMemberService: WithdrawAddGroupMemberService? {
        return try? resolver.resolve(assert: WithdrawAddGroupMemberService.self, cache: true)
    }

    // 获取被At的群外的人
    public func getAtOuterChatterIDs(_ messageID: String) -> Observable<[String]> {
        return messageAPI?
            .getSystemMessageActionPayload(messageID: messageID, actionType: .inviteAtChatters)
            .map { $0.atChatterIds } ?? .empty()
    }

    public func getActionURL(_ messageID: String) -> Observable<String> {
        return messageAPI?
            .getSystemMessageActionPayload(messageID: messageID, actionType: .url)
            .map { $0.url } ?? .empty()
    }

    // 检查已经在群里的人
    public func checkIsChattersInChat(_ chatterIDS: [String], chatId: String) -> Observable<[String]> {
        return (try? resolver.resolve(assert: ChatAPI.self, cache: true).checkChattersInChat(chatterIds: chatterIDS, chatId: chatId)) ?? .empty()
    }

    public func sendLarkCommandPayload(cmd: Int32, payload: Data) -> Observable<Void> {
        return messageAPI?.sendLarkCommandPayload(cmd: cmd, payload: payload).map { _ in return } ?? .empty()
    }

    public func showGuide(key: String) {
        pageAPI?.showGuide(key: key)
    }
}

public final class SystemMessageTappedLabel: UILabel {
    private var tapStart = false
    public var hightlightedBGColor: UIColor?
    public var onTapped: ((_ label: SystemMessageTappedLabel) -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let insets = UIEdgeInsets(top: 0, left: -self.font.pointSize, bottom: 0, right: -self.font.pointSize)
        if bounds.inset(by: insets).contains(point) {
            return self
        }
        return super.hitTest(point, with: event)
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        tapStart = true
        backgroundColor = hightlightedBGColor
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else {
            tapStart = false
            return
        }
        if !self.frame.contains(point) {
            tapStart = false
            backgroundColor = .clear
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if tapStart {
            onTapped?(self)
        }
        tapStart = false
        backgroundColor = .clear
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        tapStart = false
        backgroundColor = .clear
    }
}

open class SimilarToSystemCellViewModel<C: ViewModelContext>: CellViewModel<C> {
    open internal(set) var labelAttrText: NSMutableAttributedString = NSMutableAttributedString(string: "")
    open internal(set) var textLinks: [LKTextLink] = []

    open var isUserInteractionEnabled: Bool {
        return true
    }

    let font = UIFont.ud.body2
    let chatterForegroundColor = UIColor.ud.N600

    public func appendClickableContent(text: String, onTapped: ((_ label: SystemMessageTappedLabel) -> Void)?) {
        let textWidth = text.lu.width(
            font: font,
            height: font.pointSize
        )
        let attachment = LKAsyncAttachment(viewProvider: { [weak self] in
            guard let `self` = self else { return UIView() }
            let label = SystemMessageTappedLabel(frame: .zero)
            label.text = text
            label.font = self.font
            label.textColor = UIColor.ud.textLinkNormal
            label.onTapped = onTapped
            return label
        }, size: CGSize(width: textWidth, height: font.rowHeight))
        attachment.fontAscent = font.ascender
        attachment.fontDescent = font.descender
        attachment.margin.left = 5
        labelAttrText.append(NSAttributedString(
            string: LKLabelAttachmentPlaceHolderStr,
            attributes: [
                LKAttachmentAttributeName: attachment
            ]
        ))
    }
}

open class SystemCellViewModel<C: SystemContentContext>: SimilarToSystemCellViewModel<C> {
    private lazy var logger = Logger.log(
        SystemCellViewModel.self,
        category: "Module.IM.SystemCellViewModel")
    override open var identifier: String {
        return "system"
    }

    var chatComponentTheme: ChatComponentTheme {
        let scene = self.context.getChatThemeScene()
        return ChatComponentThemeManager.getComponentTheme(scene: scene)
    }

    open private(set) var metaModel: CellMetaModel

    open var message: Message {
        return metaModel.message
    }

    public init(metaModel: CellMetaModel, context: C) {
        self.metaModel = metaModel
        super.init(context: context, binder: SystemCellComponentBinder(context: context))
        formatRichSystemText()
        self.calculateRenderer()
    }

    public init(metaModel: CellMetaModel, context: C, binder: ComponentBinder<C>) {
        self.metaModel = metaModel
        super.init(context: context, binder: binder)
        formatRichSystemText()
        self.calculateRenderer()
    }

    public func update(metaModel: CellMetaModel) {
        self.metaModel = metaModel
        formatRichSystemText()
        self.calculateRenderer()
    }

    private func formatRichSystemText() {
        guard let content = message.content as? SystemContent else {
            assertionFailure("Content must be SystemContent")
            return
        }
        let result = LarkCoreUtils.parseSystemContent(content, chatterForegroundColor: chatterForegroundColor) { [weak self] (value) in
            self?.onTap(value, systemContent: content)
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        self.labelAttrText = NSMutableAttributedString(string: result.text, attributes: [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: chatComponentTheme.systemTextColor
        ])
        self.textLinks = result.textLinks
        self.addClickableContentIfNeeded(content: content)
    }

    private func tryToTrack(systemType: SystemContent.SystemType, contentValue: SystemContent.ContentValue) {
        if systemType == .createP2PSource {
            switch contentValue.type {
            case .url:
                Tracker.post(
                    TeaEvent(Homeric.CHAT_SYSTEMMESSAGE_BEADDED_SETTINGS_CLICK)
                )
            @unknown default:
                break
            }
        }
    }

    private func onTap(_ value: SystemContent.ContentValue, systemContent: SystemContent) {
        let systemType = systemContent.systemType

        /// .userCheckOthersTelephone 为老的系统消息类型（version = 0）
        /// 其中的 SystemContent.ContentValueType 为 .unknown 类型
        /// 因此这里做特化，需要响应点击事件
        if systemType == .userCheckOthersTelephone {
            let body = PersonCardBody(chatterId: value.id,
                                      chatId: metaModel.getChat().id,
                                      source: .chat)
            if Display.phone {
                context.navigator(type: .push, body: body, params: nil)
            } else {
                context.navigator(
                    type: .present,
                    body: body,
                    params: NavigatorParams(wrap: LkNavigationController.self, prepare: { vc in
                        vc.modalPresentationStyle = .formSheet
                    }))
            }
            return
        }

        switch value.type {
        case .user, .chatter, .bot:
            self.tryToTrack(systemType: systemType, contentValue: value)
            let body = PersonCardBody(chatterId: value.id,
                                      chatId: metaModel.getChat().id,
                                      source: .chat)
            if Display.phone {
                context.navigator(type: .push, body: body, params: nil)
            } else {
                context.navigator(
                    type: .present,
                    body: body,
                    params: NavigatorParams(wrap: LkNavigationController.self, prepare: { vc in
                        vc.modalPresentationStyle = .formSheet
                    }))
            }
        case.url:
            self.tryToTrack(systemType: systemType, contentValue: value)
            if let url = URL(string: value.link)?.lf.toHttpUrl() {
                context.navigator(type: .push, url: url, params: NavigatorParams(
                    context: ["scene": "messenger", "loaction": "messenger_system_message"]
                ))
            }
        case .chat:
            let body = GroupCardSystemMessageJoinBody(chatId: value.id)
            context.navigator(type: .push, body: body, params: nil)
        case .action:
            if systemContent.version == 1 {
                let actionID = value.actionID
                guard let action = systemContent.itemActions[actionID]?.action else {
                    return
                }
                switch action {
                case .inviteAtChatters(let inviteAtChatters):
                    let atOuterIDsOb: Observable<[String]> = .just(inviteAtChatters.atChatterIds.map { "\($0)" })
                    self.inviteAtOuterActionTrigger(atOuterIDsOb)
                case .url(let urlInfo):
                    trackUserJoinGroupAutoMuteIfNeeded()
                    if let url = URL(string: urlInfo.ios)?.lf.toHttpUrl() {
                        context.navigator(type: .push, url: url, params: nil)
                        break
                    }
                    if let url = URL(string: urlInfo.common)?.lf.toHttpUrl() {
                        context.navigator(type: .push, url: url, params: nil)
                        break
                    }
                    self.logger.error("get action url failed",
                                      additionalData: ["messageID": metaModel.message.id])
                case .larkCommand(let larkCommand):
                    let messageID = metaModel.message.id
                    self.context
                        .sendLarkCommandPayload(cmd: larkCommand.cmd, payload: larkCommand.payload)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onError: { [weak self] error in
                            self?.logger.error(
                                "sendLarkCommandPayload failed",
                                additionalData: ["messageID": messageID],
                                error: error)
                            self?.handleLarkCommandError(larkCommand: larkCommand, error: error)
                        }).disposed(by: disposeBag)
                 /// 该消息类型暂时无用，给PC端做hover态
                case .chatterTooltip(_):
                    break
                @unknown default:
                    assert(false, "new value")
                    break
                }
                return
            }
            switch value.actionType {
            case .unknownActType:
                break
            case .url:
                self.actionURLTrigger()
            case .inviteAtChatters:
                let atOuterIDsOb = self.context.getAtOuterChatterIDs(message.id)
                self.inviteAtOuterActionTrigger(atOuterIDsOb)
            @unknown default:
                assert(false, "new value")
                break
            }
        case .text, .department, .unknown:
            break
        @unknown default:
            assert(false, "new value")
            break
        }
    }

    private func handleLarkCommandError(larkCommand: RustPB.Basic_V1_SystemMessageItemAction.LarkCommand, error: Error) {
        guard let window = self.context.targetVC?.view.window, self.isErrorToastInWhiteList(command: Int(larkCommand.cmd)) else {
            return
        }
        //目前只处理同意沟通申请的error
        UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_Core_Label_ActionFailed_Toast, on: window, error: error)
    }

    // 处理error的白名单
    private func isErrorToastInWhiteList(command: Int) -> Bool {
        // 目前只处理同意沟通申请的error
        let whiteList = [ServerPB.ServerPB_Improto_Command.messageAgreeP2PChatPermission.rawValue]
        if whiteList.contains(command) {
            return true
        }
        return false
    }

    private func addClickableContentIfNeeded(content: SystemContent) {
        switch content.systemType {
        case .userInviteOthersJoin, .userJoinViaQrCode, .userJoinViaShare,
             .userInviteOthersJoinCryptoChat, .userJoinViaGroupLink, .userInviteBotJoin,
             .userInviteOthersJoinCircle, .userInviteOthersJoinCircleByInvitationCard, .userInviteOthersJoinCircleByQrCode,
             .userInviteBotJoinCircle, .userInviteOthersJoinCircleByLink, .userInviteOthersChatterChatDepartmentJoin,
             .groupNewMembersCanViewHistoryMessages,
             .userInviteOthersJoinChatMessage,
             .userInviteOthersJoinChatMessageNoHistory,
             .userJoinViaShareNew,
             .userJoinViaShareNoHistory,
             .userJoinViaQrNew,
             .userJoinViaQrCodeNoHistory,
             .userJoinChatByLink,
             .userJoinChatByLinkNoHistory,
             .userInviteOthersChatterChatDepartmentJoinNew,
             .userInviteOthersChatterChatDepartmentJoinNoHistory,
             .larkImCreateGroupUserAndGroupOwnerInvite,
             .larkImCreateGroupUserAndDepartmentOwnerInvite,
             .larkImCreateGroupGroupAndDepartmentOwnerInvite,
             .larkImCreateGroupUserAndGroupAndDepartmentOwnerInvite,
             .larkImEnterGroupUserAndGroupChatHistoryYesInviter,
             .larkImEnterGroupUserAndGroupChatHistoryNoInviter,
             .larkImEnterGroupUserAndDepartmentChatHistoryYesInviter,
             .larkImEnterGroupUserAndDepartmentChatHistoryNoInviter,
             .larkImEnterGroupGroupAndDepartmentChatHistoryYesInviter,
             .larkImEnterGroupGroupAndDepartmentChatHistoryNoInviter,
             .larkImEnterGroupUserAndGroupAndDepartmentChatHistoryYesInviter,
             .larkImEnterGroupLarkImEnterGroupUserAndGroupAndDepartmentChatHistoryNoInviter:
            addWithdrawAddChatterContent(content: content)
        case .checkUserPhoneNumber,
                .userCheckOthersTelephone:
            addCallContent(content: content)
        case .autoOpenTypingTranslate:
            addTurnOffRealTimeTranslateContent()
        case .highlightMessagesFromContactToStayInformed:
            addSpecialFocusContent(content: content)
        @unknown default:
            break
        }
    }

    /// 添加点击重拨/点击回拨
    private func addCallContent(content: SystemContent) {
        var isMe: Bool = false
        if let fromChatter = content.triggerUser {
            isMe = self.context.isMe(fromChatter.id, chat: self.metaModel.getChat())
        }
        let origintitle = isMe ?
            BundleI18n.LarkMessageCore.Lark_Legacy_ClickToCall :
            BundleI18n.LarkMessageCore.Lark_Legacy_ClickToCallBack

        let textWidth = origintitle.lu.width(
            font: font,
            height: font.pointSize
        )
        appendClickableContent(text: origintitle) { [weak self] _ in
            guard let self = self, let chatter = isMe ? content.callee : content.triggerUser else { return }
            self.context.callContacts(chatter.id)
        }
    }

    //添加撤回群成员邀请点击文案
    private func addWithdrawAddChatterContent(content: SystemContent) {
        let fromUserId = content.systemContentValues["from_user"]?.contentValues.first?.id ?? ""
        guard self.context.isMe(fromUserId, chat: metaModel.getChat()) else {
            return
        }

        appendClickableContent(text: BundleI18n.LarkMessageCore.Lark_Groups_RevokeInvite) { [weak self] label in
            guard let `self` = self else { return }
            var chatterNames: [String: String] = [:]
            var chatNames: [String: String] = [:]
            var departmentNames: [String: String] = [:]
            let chatterIds = content.systemContentValues["to_chatters"]?.contentValues.map({ (value) -> String in
                chatterNames[value.id] = value.value
                return value.id
            }) ?? []
            let chatIds = content.systemContentValues["from_chat"]?.contentValues.map({ (value) -> String in
                chatNames[value.id] = value.value
                return value.id
            }) ?? []
            let departmentIds = content.systemContentValues["from_dept"]?.contentValues.map({ (value) -> String in
                departmentNames[value.id] = value.value
                return value.id
            }) ?? []
            var way: AddMemeberWay = .viaInvite
            if content.systemType == .userJoinViaQrCode
                || content.systemType == .userInviteOthersJoinCircleByQrCode
                || content.systemType == .userJoinViaQrNew
                || content.systemType == .userJoinViaQrCodeNoHistory {
                way = .viaQrCode
            } else if content.systemType == .userJoinViaShare
                        || content.systemType == .userInviteOthersJoinCircleByInvitationCard
                        || content.systemType == .userJoinViaShareNew
                        || content.systemType == .userJoinViaShareNoHistory {
                way = .viaShare
            } else if content.systemType == .userJoinViaGroupLink
                        || content.systemType == .userInviteOthersJoinCircleByLink
                        || content.systemType == .userJoinChatByLink
                        || content.systemType == .userJoinChatByLinkNoHistory {
                way = .viaLink
            }

            guard let fromVC = self.context.targetVC else { return }
            self.context
                .withdrawAddGroupMemberService?
                .withdrawMembers(
                    chatId: self.message.channel.id,
                    isThread: self.metaModel.getChat().chatMode == .threadV2,
                    entity: WithdrawEntity(chatterIds: chatterIds,
                                           chatterNames: chatterNames,
                                           chatIds: chatIds,
                                           chatNames: chatNames,
                                           departmentIds: departmentIds,
                                           departmentNames: departmentNames),
                    messageId: self.message.id,
                    messageCreateTime: self.message.createTime,
                    way: way,
                    from: fromVC,
                    sourveView: label)
        }
    }

    //添加 关闭边写边译 文案
    func addTurnOffRealTimeTranslateContent() {
        appendClickableContent(text: BundleI18n.LarkMessageCore.Lark_IM_TranslationAsYouTypeOff_Button) { [weak self] _ in
            guard let `self` = self else { return }
            guard self.metaModel.getChat().typingTranslateSetting.isOpen else {
                if let window = self.context.targetVC?.view.window {
                    UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_TranslateAsYouTypeOff_SystemText, on: window)
                }
                return
            }
            IMTracker.Chat.Main.Click.closeTranslation(self.metaModel.getChat(), self.context.trackParams[PageContext.TrackKey.sceneKey] as? String, location: .chat_view)
            let chatId = self.metaModel.getChat().id
            self.context.chatAPI?.updateChat(chatId: chatId, isRealTimeTranslate: false,
                                             realTimeTranslateLanguage: self.metaModel.getChat().typingTranslateSetting.targetLanguage)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.context.showGuide(key: PageContext.GuideKey.typingTranslateOnboarding)
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    /// 把服务器返回的错误显示出来
                    let showMessage = BundleI18n.LarkMessageCore.Lark_Setting_PrivacySetupFailed
                    if let window = self.context.targetVC?.view.window {
                        UDToast.showFailure(with: showMessage, on: window, error: error)
                    }
                    self.logger.error("update chat isRealTimeTranslate by click systemMessage failed",
                                      additionalData: ["MessageID": self.metaModel.message.id,
                                                       "ChatID": chatId])
                }).disposed(by: self.disposeBag)
        }
    }

    //添加 设为星标联系人 文案
    func addSpecialFocusContent(content: SystemContent) {
        let chat = self.metaModel.getChat()
        guard chat.type == .p2P else { return }
        appendClickableContent(text: BundleI18n.LarkMessageCore.Lark_IM_ProfileSettings_AddToVIPContacts) { [weak self] _ in
            guard let self = self,
                  let targetVC = self.context.targetVC else { return }
            let chatId = chat.id
            let chatterId = chat.chatterId
            var body = PersonCardBody(chatterId: chatterId,
                                      chatId: chatId,
                                      fromWhere: .chat,
                                      source: .chat)
            body.needToPushSetInformationViewController = true
            self.context.navigator.presentOrPush(
                body: body,
                wrap: LkNavigationController.self,
                from: targetVC,
                prepareForPresent: { vc in
                    vc.modalPresentationStyle = .formSheet
                },
                animated: false)

            IMTracker.Chat.Main.Click.Msg.setStarredContactByClickSystemMessage(chat)
        }
    }

    private func actionURLTrigger() {
        trackUserJoinGroupAutoMuteIfNeeded()
        let messageID = metaModel.message.id
        self.context.getActionURL(messageID)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (url) in
                guard let context = self?.context else { return }
                if let url = URL(string: url)?.lf.toHttpUrl() {
                    context.navigator(type: .push, url: url, params: nil)
                }
            }, onError: { [weak self] (error) in
                self?.logger.error(
                    "get action url failed",
                    additionalData: ["messageID": messageID],
                    error: error)
            }).disposed(by: disposeBag)
    }

    /// @群外的人系统消息点击事件
    /// 1. 判定加人权限是不是仅群主可加人
    /// 2. 判定是否所有群成员都在群内
    /// 3. 走加人入群的流程
    private func inviteAtOuterActionTrigger(_ atOuterIDsOb: Observable<[String]>) {
        SystemTracker.trackAtOuterInvite()
        // 1. 判定加人权限是不是仅群主可加人
        if metaModel.getChat().addMemberPermission == .onlyOwner {
            DispatchQueue.main.async {
                if let window = self.context.targetVC?.view.window {
                    UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_Legacy_OnlyAdminCanAddNewMember, on: window)
                }
            }
            return
        }

        let chatID = metaModel.getChat().id
        let messageID = message.id

        atOuterIDsOb
            .flatMap { [weak self] (atOuterIDs) -> Observable<[String]> in
                guard let self = self else { return .empty() }

                // IDs 判空
                if atOuterIDs.isEmpty {
                    self.logger.error(
                        "get at outer chatter ids empty",
                        additionalData: ["chatID": chatID, "messageID": messageID])
                    return .empty()
                }

                return self.context.checkIsChattersInChat(atOuterIDs, chatId: self.metaModel.getChat().id)
                    .map { Array(Set(atOuterIDs).subtracting($0)) }
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (notInChatIOuterIDs) in
                guard let self = self else { return }

                // 2.判定是否所有群成员都在群内
                if notInChatIOuterIDs.isEmpty, let window = self.context.targetVC?.view.window {
                    UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_Group_MembersAreInTheGroup, on: window)
                } else {
                    // 3. 走加人入群的流程
                    let body = JoinGroupApplyBody(
                        chatId: chatID,
                        way: .viaMentionInvitation(
                            inviterId: self.context.currentChatterID,
                            chatterIDs: notInChatIOuterIDs)
                    )
                    self.context.navigator(type: .open, body: body, params: nil)
                }
            }, onError: { [weak self] (error) in
                self?.logger.error(
                    "get at outer not in chat ids error",
                    additionalData: ["chatID": chatID, "messageID": messageID],
                    error: error)
            }).disposed(by: disposeBag)
    }

    private func trackUserJoinGroupAutoMuteIfNeeded() {
        guard let content = metaModel.message.content as? SystemContent,
            content.systemType == .userJoinChatAutoMute else {
                return
        }
        SystemTracker.trackUserJoinGroupAutoMute()
    }
}

final class SystemCellComponentBinder<C: SystemContentContext>: ComponentBinder<C> {
    let props = SystemCellComponent<C>.Props()
    let style = ASComponentStyle()

    lazy var _component: SystemCellComponent<C> = .init(props: .init(), style: .init(), context: nil)

    override var component: ComponentWithContext<C> {
        return _component
    }

    override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? SystemCellViewModel<C> else {
            assertionFailure()
            return
        }
        props.labelAttrText = vm.labelAttrText
        props.textLinks = vm.textLinks
        props.chatComponentTheme = vm.chatComponentTheme
        props.isUserInteractionEnabled = vm.isUserInteractionEnabled
        _component.props = props
    }

    override func buildComponent(key: String? = nil, context: C? = nil) {
        self._component = SystemCellComponent(props: props, style: style, context: context)
    }
}
