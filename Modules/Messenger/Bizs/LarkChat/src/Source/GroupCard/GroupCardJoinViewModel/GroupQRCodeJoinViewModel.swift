//
//  GroupQRCodeJoinViewModel.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/6/6.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import RxCocoa
import LarkUIKit
import LarkCore
import EENavigator
import LarkSDKInterface
import LarkMessengerInterface
import LKCommonsLogging
import LarkAccountInterface
import WebBrowser
import LarkFeatureGating
import LarkMessageCore
import LarkContainer

private enum JoinButtonEventType {
    case joinGroup
    case joinOrganization
    case switchOrganization(chatterID: String)
}

final class GroupQRCodeJoinViewModel: GroupCardJoinViewModelProtocol, UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(GroupQRCodeJoinViewModel.self, category: "Module.IM")

    var joinStatusRelay: BehaviorRelay<JoinGroupApplyBody.Status>
    var joinButtonEnable: Bool {
        ShareGroupJoinStatusManager.isTapAbleStatus(joinStatusRelay.value)
    }
    let chatId: String
    var chat: Chat {
        info.chat
    }
    let avatarKey: String?
    private(set) var owner: Chatter?
    let ownerId: String
    private(set) var items: [GroupCardCellItem] = []
    let router: GroupCardJoinRouter
    let chatterAPI: ChatterAPI
    private(set) var isJoinButtonHidden = false

    var joinButtonTitleRelay: BehaviorRelay<String> = .init(value: BundleI18n.LarkChat.Lark_Legacy_JoinGroupChat)

    var reloadData: Driver<Void> { return _reloadData.asDriver(onErrorJustReturn: ()) }
    private let _reloadData = PublishSubject<Void>()
    private let currentChatterId: String

    private let disposeBag = DisposeBag()
    private let info: ChatQRCodeInfo
    private let token: String
    private let chatAPI: ChatAPI
    private let type: JoinButtonEventType

    init(
        userResolver: UserResolver,
        info: ChatQRCodeInfo,
        token: String
    ) throws {
        self.userResolver = userResolver
        let passportUserService = try userResolver.resolve(assert: PassportUserService.self)
        self.chatterAPI = try userResolver.resolve(assert: ChatterAPI.self)
        self.chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        self.router = try userResolver.resolve(assert: GroupCardJoinRouter.self)
        let user = passportUserService.user
        self.info = info
        self.token = token
        self.currentChatterId = user.userID

        let chat = info.chat
        self.joinStatusRelay = BehaviorRelay(value: chat.isDissolved ? .groupDisband : .unTap)
        self.chatId = chat.id
        self.ownerId = chat.ownerId
        self.avatarKey = chat.avatarKey
        self.owner = chat.owner
        let isThread = chat.chatMode == .threadV2
        self.joinStatusRelay
            .map { status in
                return ShareGroupJoinStatusManager.transfromToDisplayString(status: status,
                                                                            isTopicGroup: isThread)
            }
            .bind(to: self.joinButtonTitleRelay).disposed(by: self.disposeBag)

        let isSameOrganization = chat.tenantId == user.tenant.tenantID
        // 可以加入：同一组织任意群 / 外部群
        let canJoin = isSameOrganization || chat.isCrossTenant

        var memberCount: Int?
        if chat.isUserCountVisible {
            memberCount = Int(chat.userCount)
        }
        if canJoin {
            type = .joinGroup
            let (items, ob) = loadGroupCardJoinData(
                name: chat.name,
                memberCount: memberCount,
                description: chat.description)

            self.items = items

            ob?.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (items, owner) in
                    self?.owner = owner
                    self?.items = items
                    self?._reloadData.onNext(())
                }).disposed(by: disposeBag)
        } else {
            let tip: String
            @Provider var passportService: PassportService // Global
            if let user = passportService.userList.first(where: { $0.tenant.tenantID == chat.tenantId }) {
                // 已经加入另一个 \ Have joined
                type = .switchOrganization(chatterID: user.userID)

                tip = BundleI18n.LarkChat.Lark_Chat_Scan_QRcode_Group_External_SwitchOrganization_Tip(info.showMsg)
                joinButtonTitleRelay.accept(BundleI18n.LarkChat.Lark_Chat_Scan_QRcode_Group_External_SwitchOrganization_Button)
            } else {
                // 未加入另一个 \ Not joined

                type = .joinOrganization

                self.items = [
                    .title(chatName: chat.name),
                    .count(membersCount: memberCount),
                    .joinOrganizationTips(tips: info.showMsg)
                ]

                isJoinButtonHidden = !info.isInviterCanAddMember
                joinButtonTitleRelay.accept(BundleI18n.LarkChat.Lark_Chat_Scan_QRcode_Group_External_ApplyOrganizationPermissionYes_Button)

                ChatTracker.trackGroupCardQRCanJpin(info.isInviterCanAddMember)
                tip = info.isInviterCanAddMember ?
                    BundleI18n.LarkChat.Lark_Chat_Scan_QRcode_Group_External_ApplyOrganizationPermissionYes_Tip(info.showMsg) :
                    BundleI18n.LarkChat.Lark_Chat_Scan_QRcode_Group_External_ApplyOrganizationPermissionNo_Tip(info.showMsg)
            }

            self.items = [
                 .title(chatName: chat.name),
                 .count(membersCount: memberCount),
                 .joinOrganizationTips(tips: tip)
             ]
        }
    }

    func joinGroupButtonTapped(from: UIViewController) {
        switch type {
        case .joinGroup:
            let chatId = info.chatID
            let inviterId = info.inviterID

            let body = JoinGroupApplyBody(
                chatId: chatId,
                way: .viaQrCode(inviterId: inviterId, token: token)
            ) { [weak self] status in
                guard let self = self else { return }
                self.joinStatusRelay.accept(status)
                let isToastRemind = ShareGroupJoinStatusManager.isShowToastStatus(status)
                let mindToast = ShareGroupJoinStatusManager.transfromToTrackString(status: status)
                var extra = ["target": "none",
                             "is_toast_remind": isToastRemind ? "true" : "false"]
                if isToastRemind {
                    extra["toast_mind"] = mindToast
                }
                ChatTracker.trackImChatGroupCardClick(chat: self.chat,
                                                      click: "group_join",
                                                      extra: extra)
            }
            navigator.open(body: body, from: from)

            ChatTracker.trackGroupCardQRTapJoinType(.group)
        case .joinOrganization:
            guard let url = URL(string: info.inviterURL) else {
                Self.logger.error("join organization url init faild")
                return
            }

            navigator.push(body: WebBody(url: url), from: from)

            ChatTracker.trackGroupCardQRTapJoinType(.organization)
        case .switchOrganization(let userID):
            @Provider var passportService: PassportService // Global
            passportService.switchTo(userID: userID)
            ChatTracker.trackGroupCardQRTapJoinType(.switchOrganization)
        }
    }
}
