//
//  ThreadChatViewModel.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/1/30.
//

import Foundation
import LarkModel
import LarkUIKit
import RxSwift
import RxCocoa
import LarkCore
import LarkBadge
import LarkContainer
import LarkMessageCore
import LarkAccountInterface
import LarkSDKInterface
import LarkSendMessage
import LarkFeatureGating
import LarkStorage
import RustPB

final class ThreadChatViewModel {
    private let disposeBag = DisposeBag()
    private let chatLastPositionPublish: PublishSubject<Void> = PublishSubject<Void>()
    private let chatIsAllowPostPublic: PublishSubject<Bool> = PublishSubject<Bool>()

    private(set) var localLeaveGroupChannel: Driver<PushLocalLeaveGroupChannnel> = .empty()
    var deleteMeFromChannelDriver: Driver<String>
    let dependency: ThreadChatViewModelDependency

    // 公开群相关逻辑
    private var isTeamVisitorMode: Bool?
    private var teamChatModeSwitchRelay = BehaviorRelay<LarkModel.Chat.TeamChatModeSwitch>(value: .none)
    var teamChatModeSwitchDriver: Driver<LarkModel.Chat.TeamChatModeSwitch> {
        return teamChatModeSwitchRelay.distinctUntilChanged().asDriver(onErrorJustReturn: .none)
    }

    var chatIsAllowPost: Driver<(Bool)> {
        return chatIsAllowPostPublic.asDriver(onErrorJustReturn: false)
    }

    lazy var chatIsFrozen: Driver<Void> = {
        return self.chatWrapper.chat.distinctUntilChanged { chat1, chat2 in
            return chat1.isFrozen == chat2.isFrozen
        }
        .filter { $0.isFrozen }
        .map { _ in return }
        .asDriver(onErrorJustReturn: ())
    }()

    lazy var chatFirstMessagePositionDriver: Driver<Void> = {
      return self.chatWrapper.chat
            .distinctUntilChanged { (chat1, chat2) -> Bool in
                return chat1.firstMessagePostion == chat2.firstMessagePostion
            }
            .skip(1)
            .map { _ -> Void in return }
            .asDriver(onErrorJustReturn: ())
    }()

    var chatLastPositionDriver: Driver<()> {
        return chatLastPositionPublish.asDriver(onErrorJustReturn: ())
    }

    /// 自动翻译开关变化
    private let chatAutoTranslateSettingPublish: PublishSubject<Void> = PublishSubject<Void>()
    var chatAutoTranslateSettingDriver: Driver<()> {
        return chatAutoTranslateSettingPublish.asDriver(onErrorJustReturn: ())
    }

    let chatAPI: ChatAPI
    let chatWrapper: ChatPushWrapper
    var pushCenter: PushNotificationCenter { dependency.pushCenter }
    let postSendService: PostSendService

    var chat: Chat {
        return self.chatWrapper.chat.value
    }

    private lazy var globalStore = KVStores.Thread.global()

    var onBoardingClosedKey: KVKey<Bool> {
        let str = "LarkThread.AllTabItem.OnBoardingClosed.\(chat.id)"
        return .init(str, default: false)
    }
    var onBoardingClosed: Bool {
        get {
            return globalStore[onBoardingClosedKey]
        }
        set {
            globalStore[onBoardingClosedKey] = newValue
        }
    }

    var offlineChatUpdateDriver: Driver<Chat> {
        return dependency.offlineChatUpdateDriver
    }

    private var kickOffService: KickOffService

    init(dependency: ThreadChatViewModelDependency,
         chatWrapper: ChatPushWrapper) {
        self.chatWrapper = chatWrapper
        self.dependency = dependency
        self.chatAPI = self.dependency.chatAPI
        self.postSendService = self.dependency.postSendService
        self.kickOffService = KickOffService(chatWrapper: chatWrapper,
                                             pushLocalLeave: dependency.localLeaveGroupChannel,
                                             pushRemoveMe: dependency.deleteMeFromChannelDriver,
                                             userResolver: dependency.userResolver)
        self.deleteMeFromChannelDriver = kickOffService.generatorKickOffDriver()

        self.localLeaveGroupChannel = dependency.localLeaveGroupChannel
            .do(onNext: { [weak self] (push) in
                if push.status == .success {
                    self?.removeFeedCard()
                }
            })

        chatWrapper.chat.map({ $0.isAutoTranslate }).distinctUntilChanged().subscribe(onNext: { [weak self] (_) in
            self?.chatAutoTranslateSettingPublish.onNext(())
        }).disposed(by: self.disposeBag)

        chatWrapper.chat.distinctUntilChanged { (chat1, chat2) -> Bool in
            return chat1.lastThreadPosition >= chat2.lastThreadPosition
        }.skip(1).map { (_) -> Void in
            return
        }.bind(to: self.chatLastPositionPublish).disposed(by: self.disposeBag)

        chatWrapper.chat.distinctUntilChanged {
            $0.isAllowPost == $1.isAllowPost
        }.map { (chat) -> Bool in
            return chat.isAllowPost
        }.bind(to: self.chatIsAllowPostPublic).disposed(by: disposeBag)

        handleSwitchTeamChatMode()
    }

    func removeFeedCard() {
        var channel = RustPB.Basic_V1_Channel()
        channel.type = .chat
        channel.id = self.chatWrapper.chat.value.id
        dependency.feedAPI.removeFeedCard(channel: channel, feedType: .chat).subscribe().disposed(by: self.disposeBag)
    }

    deinit {
        /// 退会话时，清空一次标记
        self.dependency.translateService.resetMessageCheckStatus(key: chatWrapper.chat.value.id)
    }
}

// MARK: - 处理团队公开群 用户身份转换逻辑
extension ThreadChatViewModel {
    private func handleSwitchTeamChatMode() {
        guard Chat.isTeamEnable(fgService: self.dependency.userResolver.fg) else { return }
        chatWrapper.chat.subscribe(onNext: { [weak self] newChat in
            guard let self = self else { return }
            guard !newChat.isDissolved else {
                ThreadChatController.logger.info("threadTrace/teamlog/isDissolved chatId: \(newChat.id)")
                return
            }
            // 在公开团队群下才有身份切换的问题
            guard newChat.isTeamOpenGroupForAnyTeam else { return }
            let old = self.isTeamVisitorMode
            let new = newChat.isTeamVisitorMode
            guard new != old else { return }
            ThreadChatController.logger.info("threadTrace/teamlog/identity chatId: \(newChat.id), \(new ? "vistor" : "member")")
            // 记录下新的群模式
            self.isTeamVisitorMode = new
            // old被记录下来了，才可以处理转换逻辑
            guard let old = old else { return }
            let isOldVisitor = old
            let isNowGroupMember = newChat.role == .member
            var changed: LarkModel.Chat.TeamChatModeSwitch = .none
            if isOldVisitor && isNowGroupMember {
                // 访客变为群成员
                changed = .visitorToMember
            } else if !isOldVisitor && !isNowGroupMember {
                // 群成员变为访客
                changed = .memberToVisitor
            }
            guard changed != .none else { return }
            ThreadChatController.logger.info("threadTrace/teamlog/switch chatId: \(newChat.id), \(changed)")
            self.teamChatModeSwitchRelay.accept(changed)
        }).disposed(by: self.disposeBag)
    }
}
