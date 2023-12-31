//
//  SystemMessageJoinViewModel.swift
//  Action
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
import RxRelay
import LarkSDKInterface
import LarkMessengerInterface
import LarkMessageCore

final class SystemMessageJoinViewModel: GroupCardJoinViewModelProtocol {
    let chatId: String
    var joinStatusRelay: BehaviorRelay<JoinGroupApplyBody.Status>
    var joinButtonEnable: Bool {
        ShareGroupJoinStatusManager.isTapAbleStatus(joinStatusRelay.value)
    }
    var joinButtonTitleRelay: BehaviorRelay<String> = .init(value: BundleI18n.LarkChat.Lark_Legacy_JoinGroupChat)
    private(set) var avatarKey: String?
    private(set) var owner: Chatter?
    let ownerId: String
    private(set) var items: [GroupCardCellItem] = []
    let router: GroupCardJoinRouter
    let chatterAPI: ChatterAPI
    private(set) var isJoinButtonHidden: Bool = true

    var reloadData: Driver<Void> { return _reloadData.asDriver(onErrorJustReturn: ()) }
    private var _reloadData = PublishSubject<Void>()

    private var currentChatterId: String
    private let disposeBag = DisposeBag()
    let chat: Chat

    init(
        chat: Chat,
        chatterAPI: ChatterAPI,
        currentChatterId: String,
        router: GroupCardJoinRouter
    ) {
        self.chat = chat
        self.chatterAPI = chatterAPI
        self.currentChatterId = currentChatterId
        self.router = router

        self.joinStatusRelay = BehaviorRelay(value: chat.isDissolved ? .groupDisband : .unTap)
        self.chatId = chat.id
        self.avatarKey = chat.avatarKey
        self.owner = chat.owner
        self.ownerId = chat.ownerId

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
    }

    func joinGroupButtonTapped(from: UIViewController) {
        // 系统消息群卡片不显示加群按钮，所以直接return empty()
    }
}
