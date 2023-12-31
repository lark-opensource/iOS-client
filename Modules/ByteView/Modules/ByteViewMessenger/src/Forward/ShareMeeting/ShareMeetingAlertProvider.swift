//
//  ShareMeetingAlertProvider.swift
//  LarkForward
//
//  Created by 姚启灏 on 2019/5/14.
//

import Foundation
import EditTextView
import RxSwift
import LarkSDKInterface
import LarkSendMessage
import LarkMessengerInterface
import LarkAlertController
import EENavigator
import LarkModel
import UniverseDesignToast
import ByteViewTracker
import ByteViewNetwork
import LarkContainer

// ForwardAlertFactory.register(type: ShareMeetingAlertProvider.self)
public struct ShareMeetingAlertContent: ForwardAlertContent {
    public let meetingId: String
    public let content: String
    public let style: ShareMeetingBody.Style
    public let source: ShareMeetingBody.Source
    public let canShare: (() -> Bool)?

    public init(meetingId: String, content: String, style: ShareMeetingBody.Style, source: ShareMeetingBody.Source, canShare: (() -> Bool)?) {
        self.meetingId = meetingId
        self.content = content
        self.style = style
        self.source = source
        self.canShare = canShare
    }
}

public final class ShareMeetingAlertProvider: ForwardAlertProvider {
    enum ShareError: Error {
        case banned(groups: [String])
        case lock
    }

    static let logger = Logger.getLogger("ShareForward")

    public override var maxSelectCount: Int {
        return 30
    }

    public override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? ShareMeetingAlertContent != nil {
            return true
        }
        return false
    }

    public override func getFilter() -> ForwardDataFilter? {
        return { $0.type != .bot }
    }

    public override func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        //会议分享因后端接口限制暂时置灰话题
        let includeConfigs: IncludeConfigs = [
            ForwardUserEnabledEntityConfig(),
            ForwardGroupChatEnabledEntityConfig(),
            ForwardBotEnabledEntityConfig()
        ]
        return includeConfigs
    }

    public override func getTitle(by: [LarkMessengerInterface.ForwardItem]) -> String? {
        return I18n.Lark_View_ShareMeetingToColon
    }

    public override func beforeShowAction() {
        /// 展示ConfirmContentVC前调用的逻辑
        guard let alertContent = content as? ShareMeetingAlertContent else { return }
        if alertContent.style == .link {
            VCTracker.post(name: .vc_vr_qr_code_scan, params: ["conference_id": alertContent.meetingId])
        }
    }

    public override func dismissAction() {
        /// 点击关闭页面时调用的逻辑
        guard let alertContent = content as? ShareMeetingAlertContent else { return }
        if alertContent.style == .card {
            VCTracker.post(name: .public_share_click, params: [.click: "close"])
            VCTracker.post(name: .public_share_click,
                           params: [.click: "close", "is_meeting_locked": alertContent.canShare?() == false])
            var params: TrackParams = [.click: "close", .target: "none", .location: "tab_share"]
            if alertContent.source == .meetingDetail {
                params[.from_source] = "meeting_card"
            } else if alertContent.source == .participants {
                params[.from_source] = "user_list_top"
            }
            VCTracker.post(name: .public_share_click, params: params)
        }
    }

    public override func cancelAction() {
        /// Alert cancel时调用的逻辑
        guard let alertContent = content as? ShareMeetingAlertContent else { return }
        if alertContent.style == .card {
            VCTracker.post(name: .vc_meeting_page_invite,
                           params: [.action_name: "cancel", .from_source: "share_card"])
        }
    }

    private func trackBeforeSureAction(content: ShareMeetingAlertContent, items: [LarkMessengerInterface.ForwardItem], input: String?) {
        VCTracker.post(name: .public_share_click, params: [.click: "confirm",
                                                           .shareNum: items.count,
                                                           "is_info": input != nil])
        VCTracker.post(name: .vc_meeting_page_invite,
                       params: [.action_name: "confirm", .from_source: "share_card"])
        VCTracker.post(name: .vc_in_meeting_link_share)
    }

    public override func sureAction(items: [LarkMessengerInterface.ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let alertContent = content as? ShareMeetingAlertContent else { return .just([]) }
        if let canShare = alertContent.canShare, !canShare() {
            UDToast.showTips(with: I18n.View_MV_MeetingLocked_Toast, on: from.view)
            return .error(ShareError.lock)
        }

        trackBeforeSureAction(content: alertContent, items: items, input: input)
        let meetingId = alertContent.meetingId
        let fromQRCode = alertContent.source == .QRCode
        let ids = self.itemsToIds(items)
        var content: String?
        switch alertContent.style {
        case .link:
            content = fromQRCode ? alertContent.content : ""
        default:
            content = nil
        }
        var hud: UDToast?
        if alertContent.style == .link {
            hud = UDToast.showLoading(with: "", on: from.view)
        }
        return share(
            meetingId: meetingId,
            content: content,
            message: input,
            to: ids.chatIds,
            userIds: ids.userIds,
            fromQRCode: fromQRCode,
            style: alertContent.style
        )
        .observeOn(MainScheduler.instance)
        .do(onNext: { [weak from] (result: ([String]?, [String], String?)) in
            hud?.remove()
            if let window = from?.view.window, alertContent.style == .card, let toast = result.2 {
                UDToast.showTips(with: toast, on: window)
            }
        }, onError: { [weak self, weak from] (error) in
            hud?.remove()
            Self.logger.error("share meeting failed, meetingId: \(meetingId), error: \(error)")
            if let shareError = error as? ShareError, let from = from {
                if case .banned(let groups) = shareError {
                    self?.showBannedGoupsAlert(groups, from: from)
                }
            }
        }).flatMap { (result: ([String]?, [String], String?)) -> Observable<[String]> in
            return .just(result.1)
        }
    }

    func share(meetingId: String, content: String?, message: String?, to chatIds: [String], userIds: [String], fromQRCode: Bool, style: ShareMeetingBody.Style) -> Observable<([String]?, [String], String?)> {
        let service = ShareLinkService(userResolver: userResolver)
        return service.shareMeet(meetingId: meetingId, content: content, toUsers: userIds, groups: chatIds,
                                          fromQrCode: fromQRCode, piggybackText: style == .card ? message : nil)
        .flatMap { [weak self] response -> Observable<([String]?, [String], String?)> in
            guard let self = self else { return .empty() }
            let bannedIds = response.bannedGroupIds
            switch style {
            case .link:
                return self.handleShareMeetingLinkResult(chatIds: chatIds, userIds: userIds, bannedIds: bannedIds, message: message)
            case .card:
                return self.handleShareMeetingCardResult(response)
            }
        }
    }

    private func handleShareMeetingCardResult(_ res: ShareVideoChatResponse) -> Observable<([String]?, [String], String?)> {
        guard !res.bannedGroupIds.isEmpty, let httpClient = try? userResolver.resolve(assert: HttpClient.self) else {
            return .just((nil, [], res.targetUserPermissions == .all ? I18n.View_M_InvitationSent : nil))
        }
        return RxTransform.single {
            httpClient.getResponse(GetChatsRequest(chatIds: res.bannedGroupIds), completion: $0)
        }.map { $0.chats }
        .catchErrorJustReturn([])
        .asObservable()
        .flatMap { (groups: [ByteViewNetwork.Chat]) -> Observable<([String]?, [String], String?)> in
            var groupDict: [String: String] = [:]
            for g in groups where g.type == .group {
                groupDict[g.id] = g.name
            }
            let groupNames = res.bannedGroupIds.compactMap { groupDict[$0] }
            return .error(ShareError.banned(groups: groupNames))
        }
    }

    private func handleShareMeetingLinkResult(chatIds: [String], userIds: [String], bannedIds: [String], message: String?) -> Observable<([String]?, [String], String?)> {
        guard let forwardService = try? userResolver.resolve(assert: ForwardService.self),
              let sendMessageAPI = try? userResolver.resolve(assert: SendMessageAPI.self),
              let chatAPI = try? userResolver.resolve(assert: ChatAPI.self) else {
            return .empty()
        }
        var chatSet = Set(chatIds)
        chatSet.subtract(bannedIds)
        var userSet = Set(userIds)
        userSet.subtract(bannedIds)
        return forwardService.checkAndCreateChats(chatIds: Array(chatSet), userIds: Array(userSet))
            .flatMapLatest { (chats) -> Observable<([String]?, [String], String?)> in
                chats.forEach({ (shareTo) in
                    if let message = message, !message.isEmpty {
                        let content = RichText.text(message)
                        sendMessageAPI.sendText(context: nil,
                                                content: content,
                                                parentMessage: nil,
                                                chatId: shareTo.id,
                                                threadId: nil,
                                                stateHandler: nil)
                    }
                })
                return bannedIds.isEmpty ? .just((nil, chats.map { $0.id }, nil)) : chatAPI.chatNamesByIds(bannedIds)
                    .asObservable()
                    .flatMap { (groups: [String]) -> Observable<([String]?, [String], String?)> in
                        return .error(ShareError.banned(groups: groups))
                    }
            }
    }

    private func showBannedGoupsAlert(_ groupNames: [String], from: UIViewController) {
        guard let shareMeetingAlertContent = content as? ShareMeetingAlertContent else { return }
        let title = I18n.Lark_View_FailedInvitation
        let groupString = groupNames.joined(separator: I18n.Lark_View_EnumerationComma)
        let content = I18n.Lark_View_BannedFromPostingGroupCountGroupNameBraces(groupNames.count,
                                                                                groupString)
        let alertController = LarkAlertController()
        alertController.setTitle(text: title, alignment: .center)
        alertController.setContent(text: content)
        alertController.addPrimaryButton(text: I18n.Lark_View_OkButton)
        userResolver.navigator.present(alertController, from: from)
    }
}

private extension ChatAPI {
    func chatNamesByIds(_ ids: [String]) -> Single<[String]> {
        return fetchChats(by: ids, forceRemote: false).map({ $0.values.compactMap({ $0.name }) }).asSingle()
    }
}
