//
//  ChatViewModel.swift
//  LarkChat
//
//  Created by zc09v on 2018/4/10.
//

import UIKit
import Foundation
import LarkModel
import RxCocoa
import RxSwift
import LKCommonsLogging
import LarkUIKit
import LarkCore
import LarkSetting
import LarkBadge
import LarkMessageCore
import LarkSDKInterface
import LarkMessageBase
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkFeatureGating
import SuiteAppConfig
import EENavigator
import RustPB
import LarkContainer

/// 处理chat页面会话相关逻辑
open class ChatViewModel: AfterFirstScreenMessagesRenderDelegate, UserResolverWrapper {
    public var userResolver: UserResolver { dependency.userResolver }
    let dependency: ChatVMDependency
    public var chat: Chat {
        return self.chatWrapper.chat.value
    }
    let chatWrapper: ChatPushWrapper
    /// 进群时，群初始的badge数
    let chatInitiallyBadge: Int32
    fileprivate let disposeBag = DisposeBag()
    public var deleteMeFromChannelDriver: Driver<String>
    /// 话题模式下，创建话题btn交互优化
    public let threadModelAddButtonOptimize: Bool
    public fileprivate(set) var localLeaveGroupChannel: Driver<PushLocalLeaveGroupChannnel> = .empty()
    private let chatLastPositionPublish: PublishSubject<Void> = PublishSubject<Void>()
    public var chatLastPositionDriver: Driver<()> {
        return chatLastPositionPublish.asDriver(onErrorJustReturn: ())
    }
    /// 自动翻译开关变化
    private let chatAutoTranslateSettingPublish: PublishSubject<Void> = PublishSubject<Void>()
    public var chatAutoTranslateSettingDriver: Driver<()> {
        return chatAutoTranslateSettingPublish.asDriver(onErrorJustReturn: ())
    }

    private static let logger = Logger.log(ChatViewModel.self, category: "Business.Chat")

    public var is24HourTime: Driver<Bool> {
        return dependency.is24HourTime.skip(1)
    }

    var offlineChatUpdateDriver: Driver<Chat> {
        return dependency.offlineChatUpdateDriver
    }

    lazy var scheduleMsgEnable = dependency.scheduleSendService?.scheduleSendEnable

    var chatSettingType: P2PChatSettingBody.ChatSettingType {
        return .ignore//openAppFeed != nil ? .openappChat : .ignore
    }

    private let viewIsNotShowingCounter = OperatorCounter()
    var viewIsNotShowing: Bool {
        return viewIsNotShowingCounter.hasOperator
    }
    var viewIsNotShowingDriver: Driver<Bool> {
        return viewIsNotShowingCounter.hasOperatorObservable.asDriver(onErrorJustReturn: false)
    }

    // 公开群相关逻辑
    private var isTeamVisitorMode: Bool?
    private var teamChatModeSwitchRelay = BehaviorRelay<LarkModel.Chat.TeamChatModeSwitch>(value: .none)
    var teamChatModeSwitchDriver: Driver<LarkModel.Chat.TeamChatModeSwitch> {
        return teamChatModeSwitchRelay.distinctUntilChanged().asDriver(onErrorJustReturn: .none)
    }
    private var kickOffService: KickOffService

    init(dependency: ChatVMDependency, chatWrapper: ChatPushWrapper) {
        self.dependency = dependency
        self.chatWrapper = chatWrapper
        // 为什么在此时获取？
        // 1.因为chatWrapper的初始化依赖chat的拉取完成，初始化badge肯定也需要chat拉取完成
        // 2.而ChatViewModel的init方法在chatWrapper初始化后会同步的调用，时机比较合适
        // 3.chatInitiallyBadge在ChatMessagesViewController中使用，ChatViewModel这个角色也比较合适
        self.chatInitiallyBadge = chatWrapper.chat.value.badge
        self.kickOffService = KickOffService(chatWrapper: chatWrapper,
                                             pushLocalLeave: dependency.localLeaveGroupChannel,
                                             pushRemoveMe: dependency.deleteMeFromChannelDriver,
                                             userResolver: dependency.userResolver)
        self.deleteMeFromChannelDriver = kickOffService.generatorKickOffDriver()
        self.threadModelAddButtonOptimize = dependency.userResolver.fg.staticFeatureGatingValue(with: "im.message.thread_model_addbutton_optimize")

        chatWrapper.chat.distinctUntilChanged { (chat1, chat2) -> Bool in
            return chat1.lastMessagePosition >= chat2.lastMessagePosition
        }.skip(1).map { (_) -> Void in
            return
        }.bind(to: self.chatLastPositionPublish).disposed(by: self.disposeBag)

        self.localLeaveGroupChannel = dependency.localLeaveGroupChannel.do(onNext: { [weak self] (push) in
            if push.status == .success {
                self?.removeFeedCard()
            }
        })

        handleSwitchTeamChatMode()
    }

    deinit {
        // 退会话时清空一次标记
        self.dependency.translateService?.resetMessageCheckStatus(key: chat.id)
        print("NewChat: ChatViewModel deinit")
    }

    public func afterMessagesRender() {
        chatWrapper.chat.map({ $0.isAutoTranslate }).distinctUntilChanged().subscribe(onNext: { [weak self] (_) in
            self?.chatAutoTranslateSettingPublish.onNext(())
        }).disposed(by: self.disposeBag)

        chatWrapper.chat.distinctUntilChanged { $0.showApplyBadge == $1.showApplyBadge }
            .subscribe(onNext: { [weak self](chat) in
                guard let self = self, !self.chat.isMeeting else { return }
                self.badgeShow(for: self.settingPath, show: chat.showApplyBadge)
            }).disposed(by: self.disposeBag)

        // 获取openApp&从服务端拉取最新chatter信息，单聊有chatter，机器人聊天界面属于单聊
        if chat.type == .p2P {
            let chatterId = chat.chatterId
            self.dependency.chatterAPI?.fetchChatChatters(ids: [chatterId], chatId: self.chat.id, isForceServer: true)
                .subscribe(onNext: { [weak self] result in
                    if let chatter = result[chatterId] {
                        self?.dependency.pushCenter.post(PushChatters(chatters: [chatter]))
                    }
                }, onError: { error in
                    Self.logger.error("failed fetching chatter from remote server!", error: error)
                }).disposed(by: self.disposeBag)
            self.dependency.chatterAPI?.fetchOpenAppState(botID: chatterId).subscribe().disposed(by: self.disposeBag)
        }

        if self.dependency.pinBadgeEnable {
            self.dependency.pinReadStatusObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (push) in
                    guard let `self` = self else { return }
                    self.badgeShow(for: self.pinPath, show: !push.hasRead)
            }).disposed(by: self.disposeBag)
        }
        if self.dependency.pinBadgeEnable {
            self.dependency
                .pinAPI?
                .getPinReadStatus(chatId: self.chat.id).subscribe(onNext: { [weak self] (hasRead) in
                    guard let `self` = self else { return }
                    self.badgeShow(for: self.pinPath, show: !hasRead)
                }).disposed(by: self.disposeBag)
        }
    }

    public func removeFeedCard() {
        var channel = RustPB.Basic_V1_Channel()
        channel.type = .chat
        channel.id = self.chat.id
        dependency.feedAPI?.removeFeedCard(channel: channel, feedType: .chat).subscribe().disposed(by: self.disposeBag)
    }

    public var chatWithMyself: Bool {
        return self.dependency.currentAccountChatterId == self.chat.chatter?.id
    }

    public func setLastRead(messagePosition: Int32, offsetInScreen: CGFloat) {
        ChatViewModel.logger.info("chatTrace setLastRead \(self.chat.id) \(messagePosition) \(offsetInScreen)")
        dependency.chatAPI?.setChatLastRead(chatId: self.chat.id, messagePosition: messagePosition, offsetInScreen: offsetInScreen)
            .subscribe()
            .disposed(by: self.disposeBag)
    }

    public var showTopUnReadMessagesTipView: Bool {
        // 精简模式下不显示上电梯
        guard AppConfigManager.shared.feature(for: .messagePull).isOn && self.chat.badge > 0 else {
            return false
        }
        if chat.isTeamVisitorMode {
            return false
        }
        let userSettingStatus = self.dependency
            .userUniversalSettingService?
            .getIntUniversalUserSetting(key: "GLOBALLY_ENTER_CHAT_POSITION") ?? Int64(UserUniversalSettingKey.ChatLastPostionSetting.recentLeft.rawValue)
        if userSettingStatus == UserUniversalSettingKey.ChatLastPostionSetting.recentLeft.rawValue {
            //1、上次离开的位置
            return false
        } else if userSettingStatus == UserUniversalSettingKey.ChatLastPostionSetting.lastUnRead.rawValue {
            //2、最新一条未读消息
            return true
        } else {
            ChatViewModel.logger.info("userUniversalPageConfigFG error\(userSettingStatus)")
            return self.chat.messagePosition == .newestUnread
        }
    }

    public var showDownUnReadMessagesTipView: Bool {
        if chat.isTeamVisitorMode {
            return false
        }
        return true
    }

    public func view(isShowing: Bool, indentify: String) {
        assert(Thread.isMainThread)
        if isShowing {
            viewIsNotShowingCounter.decrease(category: indentify)
        } else {
            viewIsNotShowingCounter.increase(category: indentify)
        }
    }
}

extension ChatViewModel {
    var chatidPath: Path { return Path().prefix(Path().chat_id, with: chat.id) }

    var charMorePath: Path { return chatidPath.chat_more }

    var pinPath: Path { return charMorePath.raw(SidebarItemType.pin.rawValue) }

    var settingPath: Path { return charMorePath.raw(SidebarItemType.setting.rawValue) }

    /// 控制Badge显示
    ///
    /// - Parameters:
    ///   - path: Badge路径
    ///   - show: 是否显示
    func badgeShow(for path: Path, show: Bool, type: BadgeType = .dot(.pin)) {
        if show {
            BadgeManager.setBadge(path, type: type)
        } else {
            BadgeManager.clearBadge(path)
        }
    }
}

// MARK: - 处理团队公开群 用户身份转换逻辑
extension ChatViewModel {
    private func handleSwitchTeamChatMode() {
        guard Chat.isTeamEnable(fgService: self.userResolver.fg) else { return }
        chatWrapper.chat.subscribe(onNext: { [weak self] newChat in
            guard let self = self else { return }
            guard !newChat.isDissolved else {
                Self.logger.info("chatTrace/teamlog/isDissolved chatId: \(newChat.id)")
                return
            }
            // 在公开团队群下才有身份切换的问题
            guard newChat.isTeamOpenGroupForAnyTeam else { return }
            let old = self.isTeamVisitorMode
            let new = newChat.isTeamVisitorMode
            guard new != old else { return }
            Self.logger.info("chatTrace/teamlog/identity chatId: \(newChat.id), \(new ? "vistor" : "member")")
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
            Self.logger.info("chatTrace/teamlog/switch chatId: \(newChat.id), \(changed)")
            self.teamChatModeSwitchRelay.accept(changed)
        }).disposed(by: self.disposeBag)
    }
}
