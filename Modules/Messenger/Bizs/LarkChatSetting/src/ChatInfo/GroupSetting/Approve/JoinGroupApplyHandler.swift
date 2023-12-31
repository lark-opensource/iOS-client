//
//  JoinGroupApplyHandler.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/4/1.
//

import Foundation
import LarkUIKit
import UIKit
import LarkButton
import RxSwift
import RxCocoa
import LarkModel
import LKCommonsLogging
import UniverseDesignToast
import EENavigator
import Swinject
import LarkContainer
import LarkAlertController
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkFeatureGating
import RustPB
import Homeric
import LKCommonsTracker
import LarkCore
import UniverseDesignDialog
import LarkNavigator
import LarkLocalizations

final private class JoinGroupApplyTextField: BaseTextField {
    override func cut(_ text: String) -> (Bool, String) {
        let string = text as NSString
        let count = string.length
        return (count > maxLength,
                string.substring(with: NSRange(location: 0, length: min(count, maxLength))) as String)
    }
}

final private class JoinGroupApplyView: UIView {
    let messageLabel = UILabel()
    let textField = JoinGroupApplyTextField()

    init(tips: String,
         placeholder: String) {
        super.init(frame: .zero)
        addSubview(messageLabel)
        addSubview(textField)

        messageLabel.text = tips
        messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.textColor = UIColor.ud.N900
        messageLabel.numberOfLines = 0
        messageLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(tips.isEmpty ? 0 : 6)
            maker.left.right.equalToSuperview()
            maker.width.lessThanOrEqualTo(263).priority(.required)
        }

        textField.exitOnReturn = true
        textField.textAlignment = .left
        textField.clearButtonMode = .whileEditing
        textField.textColor = UIColor.ud.N900
        textField.backgroundColor = UIColor.ud.bgFloat
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.returnKeyType = .done
        textField.layer.masksToBounds = true
        textField.layer.cornerRadius = 6
        textField.layer.borderWidth = 1
        textField.layer.ud.setBorderColor(UIColor.ud.N300)
        textField.maxLength = 100
        textField.contentInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        textField.placeholder = placeholder
        textField.clearButtonMode = .never
        textField.setContentCompressionResistancePriority(.required, for: .horizontal)
        textField.setContentHuggingPriority(.required, for: .horizontal)
        textField.snp.makeConstraints { (maker) in
            maker.top.equalTo(messageLabel.snp.bottom).offset(8)
            maker.height.equalTo(36)
            maker.width.equalTo(263).priority(.required)
            maker.left.right.bottom.equalToSuperview()
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// 重构文档: https://bytedance.feishu.cn/space/doc/doccnX3BiDRFMsXCq3Fv7zKf6jg
final class JoinGroupApplyHandler: UserTypedRouterHandler {
    static let logger = Logger.log(JoinGroupApplyHandler.self, category: "LarkChat.JoinGroupApplyHandler")
    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    static func compatibleMode() -> Bool { ChatSetting.userScopeCompatibleMode }

    private var currentChatterId: String {
        return (try? self.userResolver.resolve(assert: PassportUserService.self).user.userID) ?? ""
    }

    private var chat: Chat?

    func handle(_ body: JoinGroupApplyBody, req: EENavigator.Request, res: Response) throws {
        // 1. 拉取chat，判断是否需要入群验证
        // 2. 如果需要：走入群验证的逻辑
        // 3. 如果不需要：加人进群，成功后如果有onSuccess回调，调用之，如果没有进群
        // 4. 说明：情况3，如果不需要，且已经是群成员，这种case不在handler中处理，由调用处判断
        let startTimeStamp = CACurrentMediaTime()
        var sdkStartTimeStamp = startTimeStamp
        var tracker: GroupChatDetailTracker?

        guard let from = req.context.from() else {
            assertionFailure("缺少 From")
            return
        }

        // keep openType, for ipad open in detail 
        let openType = req.context.openType()
        let hud: UDToast? = body.showLoadingHUD ? from.fromViewController?.viewIfLoaded.map { UDToast.showLoading(on: $0) } : nil
        try? self.userResolver.resolve(assert: ChatAPI.self)
            .fetchChats(by: [body.chatId], forceRemote: true)
            .flatMap { (chats) -> Observable<Chat> in
                if let chat = chats[body.chatId] {
                    return .just(chat)
                }

                return .error(
                    NSError(
                        domain: "JoinGroupApplyHandler fetch chat failed",
                        code: 0,
                        userInfo: ["chatId": body.chatId]
                    ) as Error
                )
            }
            .observeOn(MainScheduler.instance)
            .flatMap { [weak self] (chat) -> Observable<Void> in
                guard let self = self else { return .just(()) }
                tracker = GroupChatDetailTracker(chat: chat)
                self.chat = chat
                // 需要入群验证，走验证逻辑
                if self.checkShouldShowApplyConfirm(body.way, chat: chat) {
                    self.showApplyConfirm(body, from: from, openType: openType)
                    return .just(())
                }
                let needApply = chat.addMemberApply == .needApply
                let isGroupOwnerOrAdmin = self.currentChatterId == chat.ownerId || chat.isGroupAdmin
                if needApply && !isGroupOwnerOrAdmin {
                    // 群/部门暂不支持入群验证
                    if case .viaInvitation(_, _, _, let chatIds, let departmentIds, _) = body.way,
                       !chatIds.isEmpty || !departmentIds.isEmpty {
                        // 开启入群验证时暂不支持选择群/部门维度
                        let alertController = LarkAlertController()
                        let title = BundleI18n.LarkChatSetting.Lark_Legacy_UnableAddDptGroupContactOwnerAdmin
                        alertController.setTitle(text: title)
                        alertController.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_Legacy_LarkConfirm)
                        self.userResolver.navigator.present(alertController, from: from)
                        return .just(())
                    }
                }

                sdkStartTimeStamp = CACurrentMediaTime()
                // 走加人然后进去逻辑
                return try self.addChatChatters(
                    body: body,
                    isMember: chat.role == .member,
                    isExternal: chat.isCrossTenant,
                    isPublic: chat.isPublic
                )
                    .observeOn(MainScheduler.instance)
                    .do(onError: { (error) in
                        tracker?.actionError(error, action: .add)
                    })
                    .map { [unowned self, unowned from] (_) -> Void in
                        self.enterChat(body, navigatorFrom: from, openType: openType)
                        self.handleJoinStatus(.hadJoined, body: body)
                        return
                    }
            }
            .subscribe(onNext: { [startTimeStamp] _ in
                hud?.remove()
                let timeStamp = CACurrentMediaTime()
                tracker?.actionCost(
                    timeStamp - startTimeStamp,
                    sdkCost: timeStamp - sdkStartTimeStamp,
                    iosFetchChatCost: sdkStartTimeStamp - startTimeStamp,
                    action: .add
                )
            }, onError: { [unowned self, unowned from] (error) in
                hud?.remove()
                try? self.handle(error: error, body: body, from: from, openType: openType)
            }).disposed(by: disposeBag)

        res.end(resource: EmptyResource())
    }

    private func addChatChatters(body: JoinGroupApplyBody, isMember: Bool, isExternal: Bool, isPublic: Bool) throws -> Observable<Void> {
        let chatAPI = try self.userResolver.resolve(assert: ChatAPI.self)
        let threadAPI = try self.userResolver.resolve(assert: ThreadAPI.self)
        switch body.way {
        case .viaShare(let joinToken, let messageId, _):
            ChatSettingTracker.trackJoinGroupByGroupCard(isMember: isMember, isExternal: isExternal, isPublic: isPublic)
            return chatAPI.joinChat(joinToken: joinToken, messageId: messageId).map { _ in return }
        case .viaQrCode(let inviterId, let token):
            ChatSettingTracker.trackJoinGroupByQRCode(isMember: isMember, isExternal: isExternal, isPublic: isPublic)
            return chatAPI.addChatter(to: body.chatId, inviterId: inviterId, token: token)
        case .viaInvitation(_, _, let chatterIDs, let chatIds, let departmentIds, _):
            // 如果选取的用户均是外部联系人，上层会过滤掉，因此这里直接返回，不继续进行拉人进群操作
            if chatterIDs.isEmpty, chatIds.isEmpty, departmentIds.isEmpty { return .just(()) }
            return chatAPI.addChatters(chatId: body.chatId, chatterIds: chatterIDs, chatIds: chatIds, departmentIds: departmentIds)
        case .viaMentionInvitation(_, let chatterIDs):
            return chatAPI.addChatters(chatId: body.chatId, chatterIds: chatterIDs, chatIds: [], departmentIds: [])
        case .viaSearch, .viaShareTopic, .viaDepartmentStructure, .viaCalendar:
            return chatAPI.addChatters(chatId: body.chatId, chatterIds: [currentChatterId], chatIds: [], departmentIds: [])
        case .viaTopicGroup(let useAddMembersToTopicGroup, let isDefaultFavorite):
            // 使用TopicGroup接口
            if useAddMembersToTopicGroup {
                return threadAPI.addMembers(topicGroupID: body.chatId, memberIDs: [currentChatterId], isDefaultFavorite: isDefaultFavorite)
            } else {
                return chatAPI.addChatters(chatId: body.chatId, chatterIds: [currentChatterId], chatIds: [], departmentIds: [])
            }
        case .viaLink(_, let token):
            return chatAPI.addChatterByLink(with: token)
        case .viaTeamOpenChat(let teamId), .viaTeamChat(let teamId):
            return chatAPI.addChatters(teamId: teamId, chatId: body.chatId, chatterIds: [currentChatterId])
        case .viaLinkPageURL(let linkPageURL):
            return chatAPI.addChatters(chatId: body.chatId, chatterIds: [currentChatterId], linkPageURL: linkPageURL)
        }
    }

    // 判断是否直接发起入群申请还是先调进群接口
    private func checkShouldShowApplyConfirm(_ way: JoinGroupApplyBody.Way, chat: Chat) -> Bool {
        if case .viaTeamChat = way {
            // 如果是通过团队私密可发现来申请入群，即使群的进群验证为不需要验证，也需要弹窗
            return true
        }
        guard chat.addMemberApply == .needApply else { return false }
        if case .viaCalendar = way {
            return true
        }
        return false
    }

    private func showApplyConfirm(_ body: JoinGroupApplyBody, from: NavigatorFrom, openType: OpenType? = nil) {
        let tips: String
        var title = BundleI18n.LarkChatSetting.Lark_Group_ApplyToEnter
        var placeholder = BundleI18n.LarkChatSetting.Lark_Group_JoinGroupPlaceholder

        switch body.way {
        case .viaInvitation, .viaMentionInvitation:
            tips = BundleI18n.LarkChatSetting.Lark_Group_ApplyToEnterDesc
        case .viaShare, .viaQrCode, .viaSearch, .viaCalendar, .viaDepartmentStructure, .viaShareTopic, .viaTopicGroup, .viaLink, .viaTeamOpenChat, .viaLinkPageURL:
            tips = BundleI18n.LarkChatSetting.Lark_Group_ApplyToEnterDesc
        case .viaTeamChat(_):
            placeholder = BundleI18n.LarkChatSetting.Project_T_RequestToJoinGroup_Placeholder
            title = BundleI18n.LarkChatSetting.Project_T_RequestToJoinGroup_Button
            tips = ""
        }
        if let chat = self.chat {
            NewChatSettingTracker.imChatGroupApply(chat: chat)
        }

        let applyView = JoinGroupApplyView(tips: tips, placeholder: placeholder)
        let alertController = LarkAlertController()
        alertController.setTitle(text: title)
        alertController.setContent(view: applyView)
        alertController.addCancelButton(dismissCompletion: { [weak self] in
            self?.handleJoinStatus(.cancel, body: body)
            if let chat = self?.chat {
                NewChatSettingTracker.imChatGroupClick(chat: chat, click: "cancel", isReasonFilled: false, extra: ["target": "none"])
            }
        })
        alertController.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_Legacy_LarkConfirm,
                                         dismissCheck: { [weak self, weak alertController] in
            if applyView.textField.canResignFirstResponder {
                applyView.textField.resignFirstResponder()
            }
            if let chat = self?.chat {
                var extra: [AnyHashable: Any] = ["target": "none"]
                if let extraInfo = body.extraInfo {
                    extra += extraInfo
                }
                NewChatSettingTracker.imChatGroupClick(chat: chat,
                                                       click: "confirm",
                                                       isReasonFilled: !(applyView.textField.text?.isEmpty ?? false),
                                                       extra: extra)
            }
            self?.confirm(with: body, reason: applyView.textField.text, showHudOn: from.fromViewController?.view.window) {
                alertController?.dismiss(animated: true)
                self?.handleJoinStatus(.waitAccept, body: body)
            }
            return false
        })

        self.userResolver.navigator.present(alertController, from: from)
    }

    private func enterChat(_ body: JoinGroupApplyBody, navigatorFrom: NavigatorFrom, openType: OpenType? = nil) {
        if !body.jumpChat { return }

        let from: ChatFromWhere
        switch body.way {
        case .viaSearch, .viaTopicGroup: from = .search
        case .viaInvitation, .viaMentionInvitation, .viaLinkPageURL: from = .ignored
        case .viaShare, .viaShareTopic, .viaQrCode, .viaLink, .viaCalendar: from = .card
        case .viaDepartmentStructure: from = .profile
        case .viaTeamOpenChat, .viaTeamChat: from = .teamOpenChat
        }
        //threadChat跳转会在ChatControllerByIdBody，handler里中被转发
        let chatBody = ChatControllerByIdBody(chatId: body.chatId, fromWhere: from)
        if openType == .showDetail {
            self.userResolver.navigator.showDetail(body: chatBody, wrap: LkNavigationController.self, from: navigatorFrom)
        } else {
            self.userResolver.navigator.push(body: chatBody, from: navigatorFrom)
        }
    }

    private func handle(error: Error, body: JoinGroupApplyBody, from: NavigatorFrom, openType: OpenType? = nil) {
        func showFailure(_ view: UIView?, message: String, error: APIError) {
            if let view = view {
                UDToast.showFailure(with: message, on: view, error: error)
            }
        }
        let view = from.fromViewController?.view.window
        if let error = error.underlyingError as? APIError {
            Self.logger.error("RustPB.Basic_V1_AddChatChatterApply error, errorCode = \(error.code), errorMessage = \(error.serverMessage)")
            switch error.type {
            case .chatShareMessageExpired(let message):
                // 这里只能根据token不可用并且未到过期时间来判断被停用状态
                if case .viaShare(_, _, let isTimeExpired) = body.way, !isTimeExpired {
                    let toast = BundleI18n.LarkChatSetting.Lark_Group_InvitationDisabledToast
                    if let view = view {
                        UDToast.showFailure(with: toast, on: view)
                    }
                    self.handleJoinStatus(.ban, body: body)
                } else {
                    showFailure(view, message: message, error: error)
                    self.handleJoinStatus(.expired, body: body)
                }
            case .groupChatDissolved(let message):
                showFailure(view, message: message, error: error)
                self.handleJoinStatus(.groupDisband, body: body)
            case .hadJoinedChat:
                self.enterChat(body, navigatorFrom: from, openType: openType)
                self.handleJoinStatus(.hadJoined, body: body)
            case .noSecretChatPermission(let message):
                showFailure(view, message: message, error: error)
                self.handleJoinStatus(.noPermission, body: body)
            case .chatMemberHadFull(let message):
                switch body.way {
                case .viaInvitation(_, let isAdmin, _, _, _, _):
                    let chat = self.chat
                    var trackParams: [AnyHashable: Any] = [:]
                    if let chat = chat {
                        trackParams = IMTracker.Param.chat(chat)
                    }
                    trackParams += ["text_type": "add_member"]
                    Tracker.post(TeaEvent("im_chat_member_toplimit_view", params: trackParams))
                    func defaultAlert() {
                        let dialog = UDDialog()
                        dialog.setContent(text: message)
                        dialog.setTitle(text: BundleI18n.LarkChatSetting.Lark_GroupLimit_GroupSizeExceedLimit_PopupTitle)
                        dialog.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_GroupLimit_Lark_GroupLimit_MemberViewMaxSizeReached_PopupOKButton,
                                                dismissCompletion: {
                            var trackParams: [AnyHashable: Any] = [:]
                            if let chat = chat {
                                trackParams = IMTracker.Param.chat(chat)
                            }
                            trackParams += [
                                "text_type": "add_member",
                                "click": "confirm",
                                "target": "none"
                            ]
                            Tracker.post(TeaEvent("im_chat_member_toplimit_click", params: trackParams))
                        })
                        self.userResolver.navigator.present(dialog, from: from)
                    }

                    if isAdmin,
                       let chatId = Int64(chat?.id ?? ""),
                       let tenantId = Int64(chat?.tenantId ?? "") {
                        try? self.userResolver.resolve(assert: ChatAPI.self)
                            .pullChatMemberSetting(tenantId: tenantId, chatId: chatId)
                            .observeOn(MainScheduler.instance)
                            .subscribe { [weak self] res in
                                if res.allowApply {
                                    let dialog = UDDialog()
                                    dialog.setContent(text: message)
                                    dialog.setTitle(text: BundleI18n.LarkChatSetting.Lark_GroupLimit_GroupSizeExceedLimit_PopupTitle)
                                    dialog.addCancelButton()
                                    dialog.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_GroupLimit_GroupAdminViewMaxSizeReached_AppealPopupButton,
                                                            dismissCompletion: {
                                        var trackParams: [AnyHashable: Any] = [:]
                                        if let chat = self?.chat {
                                            trackParams = IMTracker.Param.chat(chat)
                                        }
                                        trackParams += [
                                            "text_type": "add_member",
                                            "click": "apply_permission",
                                            "target": "im_chat_member_toplimit_apply_view"
                                        ]
                                        Tracker.post(TeaEvent("im_chat_member_toplimit_click", params: trackParams))
                                        self?.userResolver.navigator.present(body: GroupApplyForLimitBody(chatId: body.chatId),
                                                                             wrap: LkNavigationController.self,
                                                                             from: from,
                                                                             prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() },
                                                                             animated: true)
                                    })
                                    self?.userResolver.navigator.present(dialog, from: from)
                                } else {
                                    defaultAlert()
                                }
                            } onError: { error in
                                defaultAlert()
                                Self.logger.error("pullChatMemberSetting error, error = \(error)")
                            } .disposed(by: disposeBag)
                        } else {
                            defaultAlert()
                        }
                default:
                    showFailure(view, message: message, error: error)
                    var trackParams: [AnyHashable: Any] = [:]
                    if let chat = self.chat {
                        trackParams = IMTracker.Param.chat(chat)
                    }
                    trackParams += ["text_type": "member_join"]
                    Tracker.post(TeaEvent("im_chat_member_toplimit_view", params: trackParams))
                }
                self.handleJoinStatus(.numberLimit, body: body)
            case .internalGroupNotSupportExternalMemberJoin(let message):
                showFailure(view, message: message, error: error)
                self.handleJoinStatus(.contactAdmin, body: body)
            // 分享者已经退群
            case .groupOrSharerDismiss(let message):
                showFailure(view, message: message, error: error)
                self.handleJoinStatus(.sharerQuit, body: body)
            case .chatMemberHadFullForCertificationTenant(let message):
                let alertController = LarkAlertController()
                alertController.setContent(text: message)
                alertController.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_IM_GroupMaximumNumberReached_GotIt_Button)
                self.userResolver.navigator.present(alertController, from: from)
                self.handleJoinStatus(.numberLimit, body: body)
            case .chatMemberHadFullForPay(let message):
                self.processChatMemberHadFullForPay(message: message, from: from)
                self.handleJoinStatus(.numberLimit, body: body)
            case .addMemberFailedWithApprove:
                self.showApplyConfirm(body, from: from, openType: openType)
            case .targetExternalCoordinateCtl(let message):
                showFailure(view, message: message, error: error)
                self.handleJoinStatus(.noPermission, body: body)
            case .externalCoordinateCtl(let message):
                showFailure(view, message: message, error: error)
                self.handleJoinStatus(.noPermission, body: body)
            case .linkAddNonCertifiedTenantRefuse(let message),
                 .qrCodeAddNonCertifiedTenantRefuse(let message),
                 .shareCardAddNonCertifiedTenantRefuse(let message):
                showFailure(view, message: message, error: error)
                self.handleJoinStatus(.nonCertifiedTenantRefuse, body: body)
            default:
                let message = BundleI18n.LarkChatSetting.Lark_Legacy_GroupAddMemberFailTip
                showFailure(view, message: message, error: error)
                self.handleJoinStatus(.fail, body: body)
            }
        } else {
            Self.logger.error("RustPB.Basic_V1_AddChatChatterApply error, error is Not APIError")
            if let view = view {
                UDToast.showTips(with: BundleI18n.LarkChatSetting.Lark_Legacy_GroupAddMemberFailTip, on: view)
            }
            self.handleJoinStatus(.fail, body: body)
        }
    }

    private func processChatMemberHadFullForPay(message: String, from: NavigatorFrom) {
        try? self.userResolver.resolve(assert: UserAPI.self).isSuperAdministrator().asObservable()
            .subscribe(onNext: { (isAdmin) in
                Tracker.post(TeaEvent(Homeric.COMMON_PRICING_POPUP_VIEW, params: [
                    "function_type": "chat_number_limit",
                    "admin_flag": isAdmin ? "true" : "false"
                ]))
            }).disposed(by: self.disposeBag)
        // link目前需要hardcode在端上
        let helpCenterHost = userGeneralSettings?.helpDeskBizDomainConfig.helpCenterHost ?? ""
        let host = helpCenterHost
        let lang = LanguageManager.currentLanguage.languageIdentifier
        let urlString = "https://\(host)/hc/\(lang)/articles/360034114413"
        let alertController = LarkAlertController()
        alertController.setContent(text: message)
        alertController.addCancelButton()
        alertController.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_Group_UplimitContactSalesButton(),
                                         dismissCompletion: { [weak self] in
            guard let self = self else { return }
            try? self.userResolver.resolve(assert: UserAPI.self).isSuperAdministrator().asObservable()
                .subscribe(onNext: { (isAdmin) in
                    Tracker.post(TeaEvent(Homeric.COMMON_PRICING_POPUP_CLICK, params: [
                        "function_type": "chat_number_limit",
                        "admin_flag": isAdmin ? "true" : "false"
                    ]))
                }).disposed(by: self.disposeBag)

            if let url = URL(string: urlString), let vc = from.fromViewController {
                self.userResolver.navigator.open(url, from: vc)
            }
        })
        self.userResolver.navigator.present(alertController, from: from)
    }

    private func confirm(with body: JoinGroupApplyBody, reason: String?, showHudOn view: UIView?, dismissHandler: @escaping () -> Void) {
        let hasReason = reason?.isEmpty == false
        var teamID: Int64?
        var eventID: String?
        var linkPageURL: String?
        switch body.way {
        case .viaInvitation, .viaMentionInvitation: ChatSettingTracker.trackApplyToInviteMember(hasReason)
        case .viaShare, .viaShareTopic: ChatSettingTracker.trackApplyToJoinGroupByGroupCard(hasReason)
        case .viaQrCode: ChatSettingTracker.trackApplyToJoinGroupByQRCode(hasReason)
        case .viaSearch, .viaDepartmentStructure, .viaTopicGroup: break
        case .viaLink: break
        case .viaCalendar(let eventId):
            eventID = eventId
        case .viaTeamOpenChat(let teamId), .viaTeamChat(let teamId):
            teamID = teamId
        case .viaLinkPageURL(let url):
            linkPageURL = url
        }

       try? self.userResolver.resolve(assert: ChatAPI.self)
            .createAddChatChatterApply(
                chatId: body.chatId,
                way: body.rustWay,
                chatterIds: self.getChatterIds(from: body),
                reason: reason,
                inviterId: body.inviterId,
                joinToken: body.joinToken,
                teamId: teamID,
                eventID: eventID,
                linkPageURL: linkPageURL
            )
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak view, weak self] (_) in
                guard let self = self else { return }
                if let view = view {
                    UDToast.showTips(with: BundleI18n.LarkChatSetting.Lark_Legacy_RequestSentApprovalPendingToast, on: view)
                }
                dismissHandler()
            }, onError: { [unowned self] (error) in
                self.handleConfirmError(error, body: body, showHudOn: view)
                dismissHandler()
            }).disposed(by: self.disposeBag)
    }

    private func handleConfirmError(_ error: Error, body: JoinGroupApplyBody, showHudOn view: UIView?) {
        JoinGroupApplyHandler.logger.error(
            "create add chatter apply error",
            additionalData: [
                "chatId": body.chatId,
                "way": "\(body.rustWay)",
                "inviterId": body.inviterId ?? "none",
                "chatterIds": self.getChatterIds(from: body).joined(),
                "joinToken": body.joinToken ?? "none"
            ],
            error: error)

        if let error = error.underlyingError as? APIError {
            switch error.type {
            case .appreveDisable(let message):
                if let view = view {
                    UDToast.showFailure(with: message, on: view, error: error)
                }
                return
            case .externalCoordinateCtl, .targetExternalCoordinateCtl:
                if let view = view {
                    UDToast.showFailure(
                        with: BundleI18n.LarkChatSetting.Lark_Contacts_CantCompleteOperationNoExternalCommunicationPermission,
                        on: view, error: error
                    )
                }
                return
            default: break
            }
            if let view = view {
                UDToast.showFailure(with: error.displayMessage, on: view, error: error)
                return
            }
        }

        if let view = view {
            UDToast.showFailure(
                with: BundleI18n.LarkChatSetting.Lark_Legacy_NetworkOrServiceError,
                on: view,
                error: error
            )
        }
    }

    private func getChatterIds(from body: JoinGroupApplyBody) -> [String] {
        switch body.way {
        case .viaQrCode, .viaSearch, .viaShare, .viaDepartmentStructure, .viaShareTopic, .viaTopicGroup, .viaLink, .viaTeamOpenChat, .viaTeamChat, .viaCalendar, .viaLinkPageURL:
            return [currentChatterId]
        case .viaInvitation(_, _, let chatterIds, _, _, _):
            return chatterIds
        case .viaMentionInvitation(_, let chatterIDs):
            return chatterIDs
        }
    }

    private func handleJoinStatus(_ status: JoinGroupApplyBody.Status, body: JoinGroupApplyBody) {
        body.callback?(status)
        let joinState: GroupJoinState
        switch status {
        case .hadJoined:
            joinState = .joined
        case .waitAccept:
            joinState = .applied
        case .expired, .fail, .cancel, .groupDisband, .unTap, .numberLimit,
             .ban, .noPermission, .sharerQuit, .contactAdmin, .nonCertifiedTenantRefuse:
            joinState = .notJoined
        }
        try? self.userResolver.userPushCenter.post(PushLocalChatJoinState(chatID: body.chatId, joinState: joinState))
    }
}

extension JoinGroupApplyBody {
    var inviterId: String? {
        switch self.way {
        case .viaQrCode(let inviterId, _):
            return inviterId
        case .viaInvitation(let inviterId, _, _, _, _, _):
            return inviterId
        case .viaMentionInvitation(let inviterId, _):
            return inviterId
        case .viaShare, .viaSearch, .viaDepartmentStructure, .viaShareTopic, .viaTopicGroup, .viaTeamOpenChat, .viaTeamChat, .viaCalendar, .viaLinkPageURL:
            return nil
        case .viaLink(let inviterId, _ ):
            return inviterId
        }
    }

    var joinToken: String? {
        switch self.way {
        case .viaShare(let joinToken, _, _):
            return joinToken
        case .viaLink(_, let joinToken):
            return joinToken
        case .viaQrCode(_, let joinToken):
            return joinToken
        case .viaInvitation, .viaSearch, .viaDepartmentStructure, .viaMentionInvitation,
                .viaShareTopic, .viaTopicGroup, .viaTeamOpenChat, .viaTeamChat, .viaCalendar, .viaLinkPageURL:
            return nil
        }
    }

    var rustWay: RustPB.Basic_V1_AddChatChatterApply.Ways {
        switch self.way {
        case .viaDepartmentStructure: return .viaDepartmentStructure
        case .viaSearch, .viaTopicGroup, .viaShareTopic: return .viaSearch
        case .viaQrCode: return .viaQrCode
        case .viaShare: return .viaShare
        case .viaInvitation, .viaMentionInvitation: return .viaInvitation
        case .viaLink: return .viaLink
        case .viaTeamOpenChat: return .viaTeamOpenChat
        case .viaTeamChat: return .viaTeamPrivateDiscoverable
        case .viaCalendar: return .viaCalendar
        case .viaLinkPageURL: return .viaChatLinkedPage
        }
    }

    var jumpChat: Bool {
        switch way {
        case .viaInvitation(_, _, _, _, _, let jump), .viaDepartmentStructure(let jump):
            return jump
        case .viaShare, .viaQrCode, .viaSearch, .viaLink, .viaCalendar:
            return true
        case .viaMentionInvitation, .viaShareTopic, .viaTopicGroup, .viaTeamOpenChat, .viaTeamChat, .viaLinkPageURL:
            return false
        }
    }
}
