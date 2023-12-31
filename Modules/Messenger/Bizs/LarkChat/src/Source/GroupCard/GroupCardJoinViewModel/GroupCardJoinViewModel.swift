//
//  GroupCardJoinViewModel.swift
//  LarkChat
//
//  Created by K3 on 2018/9/26.
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

protocol GroupShareContent {
    var avatarKey: String { get }
    var title: String { get }
    var description: String { get }
    var ownerId: String { get }
    var userCount: Int32? { get }
    var joined: Bool { get }
    var expiredTime: TimeInterval { get }
    var token: String? { get }
    var chatId: String { get }
    var messageId: String? { get set }
    var isTopicGroup: Bool { get }
    var isFromSearch: Bool { get set }
}

class GroupCardJoinViewModel: GroupCardJoinViewModelProtocol {
    var chat: Chat
    var joinStatusRelay: BehaviorRelay<JoinGroupApplyBody.Status>
    var joinButtonTitleRelay: BehaviorRelay<String> = .init(value: BundleI18n.LarkChat.Lark_Legacy_JoinGroupChat)
    var joinButtonEnable: Bool {
        ShareGroupJoinStatusManager.isTapAbleStatus(joinStatusRelay.value)
    }
    var chatId: String {
        chat.id
    }
    let avatarKey: String?
    private(set) var owner: Chatter?
    let ownerId: String
    private(set) var items: [GroupCardCellItem] = []
    let router: GroupCardJoinRouter
    let joinStatusCallback: JoinStatusCallback?
    let chatterAPI: ChatterAPI

    var reloadData: Driver<Void> { return _reloadData.asDriver(onErrorJustReturn: ()) }
    private var _reloadData = PublishSubject<Void>()

    private let chatAPI: ChatAPI
    private let groupShareContent: GroupShareContent
    private let disposeBag = DisposeBag()
    private let currentChatterId: String

    init(
        groupShareContent: GroupShareContent,
        chatterAPI: ChatterAPI,
        chatAPI: ChatAPI,
        chat: Chat,
        currentChatterId: String,
        router: GroupCardJoinRouter,
        joinStatus: JoinGroupApplyBody.Status = .unTap,
        joinStatusCallback: JoinStatusCallback?
    ) {
        self.groupShareContent = groupShareContent
        self.chatterAPI = chatterAPI
        self.chatAPI = chatAPI
        self.currentChatterId = currentChatterId
        self.chat = chat
        self.router = router
        self.joinStatusCallback = joinStatusCallback

        self.joinStatusRelay = BehaviorRelay(value: joinStatus)
        self.avatarKey = groupShareContent.avatarKey
        self.ownerId = groupShareContent.ownerId

        var memberCount: Int?
        if let userCount = groupShareContent.userCount {
            memberCount = Int(userCount)
        }
        let (items, ob) = loadGroupCardJoinData(
            name: groupShareContent.title,
            memberCount: memberCount,
            description: groupShareContent.description)

        self.items = items

        ob?.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (items, owner) in
                self?.owner = owner
                self?.items = items
                self?._reloadData.onNext(())
            }).disposed(by: disposeBag)
        let isThread = self.groupShareContent.isTopicGroup

        self.joinStatusRelay
            .map { status in
                return ShareGroupJoinStatusManager.transfromToDisplayString(status: status,
                                                                            isTopicGroup: isThread)
            }
            .bind(to: self.joinButtonTitleRelay).disposed(by: self.disposeBag)
    }

    func joinGroupButtonTapped(from: UIViewController) {
        if groupShareContent.joined { // 进入会话
            self.enterChatPage(chatId: groupShareContent.chatId )
            return
        }
        let messageId = groupShareContent.messageId
        let token = groupShareContent.token
        let way: JoinGroupApplyBody.Way
        if groupShareContent.isFromSearch {
            way = .viaSearch
        } else {
            way = .viaShare(joinToken: token ?? "",
                            messageId: messageId ?? "",
                            isTimeExpired: Date().timeIntervalSince1970 > groupShareContent.expiredTime)
        }
        let body = JoinGroupApplyBody(
            chatId: chatId,
            way: way
        ) { [weak self] status in
            guard let self = self else { return }
            self.joinStatusRelay.accept(status)
            self.joinStatusCallback?(status)
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

class GroupCardJoinByLinkPageViewModel: GroupCardJoinViewModel {

    private weak var fromViewController: UIViewController?
    private var linkPageURL: String

    init(
        fromViewController: UIViewController?,
        linkPageURL: String,
        groupShareContent: GroupShareContent,
        chatterAPI: ChatterAPI,
        chatAPI: ChatAPI,
        chat: Chat,
        currentChatterId: String,
        router: GroupCardJoinRouter,
        joinStatus: JoinGroupApplyBody.Status = .unTap,
        joinStatusCallback: JoinStatusCallback?
    ) {
        self.fromViewController = fromViewController
        self.linkPageURL = linkPageURL
        super.init(
            groupShareContent: groupShareContent,
            chatterAPI: chatterAPI,
            chatAPI: chatAPI,
            chat: chat,
            currentChatterId: currentChatterId,
            router: router,
            joinStatus: joinStatus,
            joinStatusCallback: joinStatusCallback
        )
    }

    override func joinGroupButtonTapped(from: UIViewController) {

        let chatID = self.chatId
        let body = JoinGroupApplyBody(
            chatId: chatID,
            way: .viaLinkPageURL(url: linkPageURL)
        ) { [weak self, weak from] status in
            guard let self = self else { return }
            self.joinStatusRelay.accept(status)
            self.joinStatusCallback?(status)

            guard case .hadJoined = status else {
                return
            }
            from?.dismiss(
                animated: true,
                completion: { [weak self] in
                    guard let self = self,
                          let fromViewController = self.fromViewController else { return }
                    let body = ChatControllerByIdBody(chatId: chatID, showNormalBack: true)
                    if Display.pad {
                        self.router.navigator.push(body: body, from: fromViewController)
                    } else {
                        self.router.navigator.present(body: body, wrap: LkNavigationController.self, from: fromViewController)
                    }
                }
            )
        }
        router.navigator.open(body: body, from: from)
    }
}
