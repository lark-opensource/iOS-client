//
//  RecommendGroupJoinViewModel.swift
//  LarkChat
//
//  Created by lizhiqiang on 2019/11/17.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import RxCocoa
import LarkUIKit
import LarkCore
import RxRelay
import EENavigator
import LarkSDKInterface
import LarkMessengerInterface
import LarkMessageCore

final class RecommendGroupJoinViewModel: GroupCardJoinViewModelProtocol {
    var joinStatusRelay: BehaviorRelay<JoinGroupApplyBody.Status>
    var joinButtonEnable: Bool {
        ShareGroupJoinStatusManager.isTapAbleStatus(joinStatusRelay.value)
    }
    var joinButtonTitleRelay: BehaviorRelay<String> = .init(value: BundleI18n.LarkChat.Lark_Legacy_JoinGroupChat)
    let chatId: String
    let avatarKey: String?
    private(set) var owner: Chatter?
    let ownerId: String
    private(set) var items: [GroupCardCellItem]
    let router: GroupCardJoinRouter
    let chatterAPI: ChatterAPI
    var reloadData: Driver<Void> { return _reloadData.asDriver(onErrorJustReturn: ()) }
    let _reloadData = PublishSubject<Void>()

    private let disposeBag = DisposeBag()
    let chat: Chat

    init(
        chat: Chat,
        chatterAPI: ChatterAPI,
        router: GroupCardJoinRouter
    ) {
        self.chatterAPI = chatterAPI
        self.avatarKey = chat.avatarKey
        self.chatId = chat.id
        self.owner = chat.owner
        self.ownerId = chat.ownerId
        self.router = router

        // need always show join button
        self.items = [GroupCardCellItem]()
        self.joinStatusRelay = BehaviorRelay(value: chat.isDissolved ? .groupDisband : .unTap)

        self.chat = chat

        let (items, ob) = self.loadGroupCardJoinData(
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
        let body = JoinGroupApplyBody(
            chatId: self.chatId,
            way: .viaSearch,
            showLoadingHUD: false
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
    }
}
