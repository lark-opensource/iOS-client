//
//  GroupViaLinkJoinViewModel.swift
//  LarkChat
//
//  Created by Kongkaikai on 2020/4/22.
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
import LarkMessageCore
import LarkFeatureGating
import LarkContainer

final class GroupViaLinkJoinViewModel: GroupCardJoinViewModelProtocol, UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(GroupQRCodeJoinViewModel.self, category: "Module.IM")

    var joinStatusRelay: BehaviorRelay<JoinGroupApplyBody.Status>
    // 群的添加状态
    private var shareGroupJoinStatus: JoinGroupApplyBody.Status {
        joinStatusRelay.value
    }
    var joinButtonEnable: Bool {
        ShareGroupJoinStatusManager.isTapAbleStatus(shareGroupJoinStatus)
    }
    var joinButtonTitleRelay: BehaviorRelay<String> = .init(value: BundleI18n.LarkChat.Lark_Legacy_JoinGroupChat)
    let chatId: String
    let avatarKey: String?
    private(set) var owner: Chatter?
    let ownerId: String
    private(set) var items: [GroupCardCellItem] = []
    let router: GroupCardJoinRouter
    let chatterAPI: ChatterAPI

    var reloadData: Driver<Void> { return _reloadData.asDriver(onErrorJustReturn: ()) }
    private let _reloadData = PublishSubject<Void>()
    private let currentChatterId: String

    private let disposeBag = DisposeBag()
    private let info: ChatLinkInfo
    let chat: Chat
    private let token: String
    private let chatAPI: ChatAPI

    init(
        userResolver: UserResolver,
        info: ChatLinkInfo,
        token: String
    ) throws {
        self.userResolver = userResolver
        self.chatterAPI = try userResolver.resolve(assert: ChatterAPI.self)
        self.chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        self.router = try userResolver.resolve(assert: GroupCardJoinRouter.self)
        self.info = info
        self.chat = info.chat
        self.token = token
        self.currentChatterId = userResolver.userID

        let chat = info.chat
        self.joinStatusRelay = BehaviorRelay(value: chat.isDissolved ? .groupDisband : .unTap)
        self.chatId = chat.id
        self.ownerId = chat.ownerId
        self.avatarKey = chat.avatarKey
        self.owner = chat.owner

        let (items, ob) = loadGroupCardJoinData(
            name: chat.name,
            memberCount: chat.isUserCountVisible ? Int(chat.userCount) : nil,
            description: chat.description
        )

        self.items = items

        ob?.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (items, owner) in
                self?.owner = owner
                self?.items = items
                self?._reloadData.onNext(())
            }).disposed(by: disposeBag)

        let isThread = chat.chatMode == .threadV2
        self.joinStatusRelay
            .map { status in
                return ShareGroupJoinStatusManager.transfromToDisplayString(status: status,
                                                                            isTopicGroup: isThread)
            }
            .bind(to: self.joinButtonTitleRelay).disposed(by: self.disposeBag)
    }

    func joinGroupButtonTapped(from: UIViewController) {
        ChatTracker.trackChatLinkClickThrough()
        let chatId = info.chatID
        let inviterId = info.inviterChatterID

        let body = JoinGroupApplyBody(
            chatId: chatId,
            way: .viaLink(inviterId: inviterId, token: token)
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
        router.navigator.open(body: body, from: from)

        ChatTracker.trackGroupCardQRTapJoinType(.group)
    }
}
