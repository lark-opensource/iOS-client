//
//  TeamGroupJoinViewModel.swift
//  LarkChat
//
//  Created by xiaruzhen on 2023/2/21.
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
import LarkMessageCore

final class TeamGroupJoinViewModel: GroupCardJoinViewModelProtocol {
    var joinStatusRelay: BehaviorRelay<JoinGroupApplyBody.Status>
    let chatId: String
    let chat: LarkModel.Chat
    let avatarKey: String?
    private(set) var owner: Chatter?
    let ownerId: String
    private(set) var items: [GroupCardCellItem] = []
    let router: GroupCardJoinRouter
    var reloadData: Driver<Void> {
        return _reloadData.asDriver(onErrorJustReturn: ())
    }
    private var _reloadData = PublishSubject<Void>()
    let chatterAPI: ChatterAPI
    var joinButtonTitleRelay: BehaviorRelay<String> = .init(value: BundleI18n.LarkChat.Lark_Legacy_JoinGroupChat)
    var joinButtonEnable: Bool {
        ShareGroupJoinStatusManager.isTapAbleStatus(joinStatusRelay.value)
    }
    private let teamId: Int64
    var trackInfo: [String: String] {
        return ["occasion": "team", "team_id": "\(teamId)"]
    }

    private let disposeBag = DisposeBag()
    var bottomDesc: String? = BundleI18n.Team.Project_T_GroupCard_JoinPrivateGroupBeforeViewChat_Text
    init(chatterAPI: ChatterAPI,
         chat: Chat,
         teamId: Int64,
         router: GroupCardJoinRouter) {
        self.chatterAPI = chatterAPI
        self.chat = chat
        self.router = router
        self.joinStatusRelay = BehaviorRelay(value: chat.isDissolved ? .groupDisband : .unTap)
        self.chatId = chat.id
        self.avatarKey = chat.avatarKey
        self.owner = chat.owner
        self.ownerId = chat.ownerId
        self.teamId = teamId
        bind()
    }

    func bind() {
        let (items, ob) = loadGroupCardJoinData(
            name: chat.name,
            memberCount: chat.isUserCountVisible ? Int(chat.userCount) : nil,
            description: chat.description)

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
        var teamInfo: [AnyHashable: Any] = ["occasion": "team", "team_id": "\(self.teamId)"]
        var extraInfo = teamInfo
        extraInfo["target"] = "none"
        ChatTracker.trackImChatGroupCardClick(chat: self.chat,
                                              click: "group_join",
                                              extra: extraInfo)
        let body = JoinGroupApplyBody(
            chatId: chatId,
            way: .viaTeamChat(teamId: teamId),
            extraInfo: teamInfo
        ) { [weak self] status in
            guard let self = self else { return }
            self.joinStatusRelay.accept(status)
        }
        router.navigator.open(body: body, from: from)
    }
}
