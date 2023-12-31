//
//  ThreadContainerViewModel.swift
//  LarkThread
//
//  Created by lizhiqiang on 2019/9/16.
//

import UIKit
import Foundation
import RxCocoa
import RxSwift
import LarkCore
import LarkUIKit
import LarkBadge
import LarkModel
import EENavigator
import LarkMessageCore
import LKCommonsLogging
import LarkSDKInterface
import LarkFeatureSwitch
import LarkAccountInterface
import LarkMessengerInterface
import SuiteAppConfig
import LarkFeatureGating
import LarkContainer
import LarkTab
import LarkWaterMark
import RustPB
import LarkQuickLaunchInterface

public protocol ThreadContainerViewModelDependency {
    func preloadDocFeed(_ url: String, from source: String)
}

// MARK: - ThreadContainerViewModel
final class ThreadContainerViewModel: UserResolverWrapper {
    let userResolver: UserResolver

    let chatID: String
    private(set) var useIntermediateEnable = true
    private(set) var chatWrapper: ChatPushWrapper?
    private(set) var topicGroupPushWrapper: TopicGroupPushWrapper?
    let fromWhere: ChatFromWhere

    var isDefaultTopicGroup: Bool {
        return topicGroupPushWrapper?.topicGroupObservable.value.isDefaultTopicGroup ?? false
    }
    var chat: Chat? {
        return self.chatWrapper?.chat.value
    }
    var topicGroup: TopicGroup? {
        return topicGroupPushWrapper?.topicGroupObservable.value
    }

    private let dependency: ThreadContainerViewModelDependency
    @ScopedInjectedLazy var waterMarkService: WaterMarkService?
    @ScopedInjectedLazy private var threadAPI: ThreadAPI?
    @ScopedInjectedLazy var chatAPI: ChatAPI?
    @ScopedInjectedLazy var pinAPI: PinAPI?
    @ScopedInjectedLazy var topNoticeService: ChatTopNoticeService?

    func getWaterMarkImage() -> Observable<UIView?> {
        return self.waterMarkService?.getWaterMarkImageByChatId(self.chatID, fillColor: nil)
            ?? Observable.just(nil)
    }

    /// 置顶消息管理
    lazy var topNoticeDataManger: ChatTopNoticeDataManager = {
        return ChatTopNoticeDataManager(chatId: self.chatID,
                                        pushCenter: self.pushCenter,
                                        userResolver: self.userResolver)
    }()

    private let pinReadStatusObservable: Observable<PushChatPinReadStatus>
    let pushCenter: PushNotificationCenter

    init(
        userResolver: UserResolver,
        chatID: String,
        dependency: ThreadContainerViewModelDependency,
        chat: Chat?,
        fromWhere: ChatFromWhere,
        topicGroup: TopicGroup?,
        pushCenter: PushNotificationCenter,
        getChatPushWarpper: @escaping (Chat) throws -> ChatPushWrapper,
        getTopicGroupPushWarpper: @escaping (TopicGroup) throws -> TopicGroupPushWrapper
    ) {
        self.userResolver = userResolver
        self.dependency = dependency
        self.chatID = chatID
        self.fromWhere = fromWhere
        self.getChatPushWarpper = getChatPushWarpper
        self.getTopicGroupPushWarpper = getTopicGroupPushWarpper
        self.pinReadStatusObservable = pushCenter.observable(for: PushChatPinReadStatus.self)
        self.pushCenter = pushCenter
        // 为了FG，所以支持handle中获取阻塞数据。
        if let chat = chat, let topicGroup = topicGroup {
            self.ready(chat: chat, topicGroup: topicGroup)
            self.useIntermediateEnable = false
        }
    }

    func pushChatAnnouncement(_ controller: UIViewController, chatId: String) {
        let body = ChatAnnouncementBody(chatId: chatId)
        navigator.push(body: body, from: controller)
    }

    func pushChatInfo(from controller: UIViewController,
                      action: EnterChatSettingAction) {
        guard let chat = self.chat, let topicGroup = self.topicGroup else {
            return
        }

        let body = ThreadInfoBody(
            chat: chat,
            hasModifyAccess: !topicGroup.isParticipant,
            hideFeedSetting: false,
            action: action
        )
        navigator.push(body: body, from: controller)
    }

    func pushChatSearch(_ controller: UIViewController, chatId: String) {
        let body = SearchInThreadBody(chatId: chatId, chatType: chat?.type)
        navigator.push(body: body, from: controller)
    }

    func pushChatPin(_ controller: UIViewController, chatId: String) {
        navigator.push(body: PinListBody(chatId: chatId, isThread: true), from: controller)
    }

    func topicGroupChangedObserver() -> Observable<TopicGroup>? {
        return topicGroupPushWrapper?.topicGroupObservable
            .skip(1)
            .distinctUntilChanged { (topicGroup1, topicGroup2) -> Bool in
                return topicGroup1.isParticipant == topicGroup2.isParticipant
            }.observeOn(MainScheduler.instance)
    }

    /// 开始监听Push
    func ready(chat: Chat, topicGroup: TopicGroup) {
        guard let chatWrapper = try? self.getChatPushWarpper(chat),
            let topicGroupPushWrapper = try? self.getTopicGroupPushWarpper(topicGroup)
        else { return }

        self.chatWrapper = chatWrapper
        self.topicGroupPushWrapper = topicGroupPushWrapper
        self.addObservers()
    }

    func fetchChatAndTopicGroup(by chatID: String) -> Observable<(Chat, TopicGroup)> {
        let from = fromWhere.rawValue
        return self.threadAPI?.fetchChatAndTopicGroup(
            chatID: chatID,
            forceRemote: false,
            syncUnsubscribeGroups: true
        ).observeOn(MainScheduler.instance)
        .flatMap({ (res) -> Observable<(Chat, TopicGroup)> in
            guard let result = res else {
                let error = NSError(
                    domain: "fetch topicGroup error",
                    code: 0,
                    userInfo: ["chatID": chatID]
                ) as Error
                return .error(error)
            }

            let topicGroup: TopicGroup
            if let topicGroupTmp = result.1 {
                topicGroup = topicGroupTmp
            } else {
                // 兜底方案，服务端接口问题没有返回TopicGroup时，屏蔽依赖TopicGroup的 默认小组/观察者功能，需要保证小组其他功能正常使用。
                ThreadContainerViewModel.logger.error("enter thread chat topicGroup is nil, use default topicgroup \(chatID)")
                topicGroup = TopicGroup.defaultTopicGroup(id: chatID)
            }

            ThreadContainerViewModel.logger.info("enter thread: chatID: \(chatID) topicGroupRole: \(topicGroup.userSetting.topicGroupRole)")

            ThreadTracker.trackEnterChat(chat: result.chat, from: from)
            ThreadPerformanceTracker.updateRequestCost(trackInfo: result.trackInfo)

            return .just((result.0, topicGroup))
        }) ?? Observable.error(UserScopeError.disposed)
    }

    func preloadFirstScreenData(chatID: String, position: Int32?) -> Observable<Void> {
        var channel = RustPB.Basic_V1_Channel()
        channel.id = chatID
        channel.type = .chat

        var scene = GetDataScene.firstScreen
        if let positionOfThread = position {
            scene = .specifiedPosition(positionOfThread)
        }
        Self.logger.info("fetchThreads track chatId:\(chatID) preloadFirstScreenData")
        return self.threadAPI?.fetchThreads(
            channel: channel,
            scene: scene,
            redundancyCount: 1,
            count: 6,
            needReplyPrompt: false
        ).map({ (_) -> Void in return })
        ?? Observable.error(UserScopeError.disposed)
    }

    // MARK: private
    private var disposeBag = DisposeBag()
    private static let logger = Logger.log(ThreadContainerViewModel.self, category: "LarkThread")
    private let getChatPushWarpper: (Chat) throws -> ChatPushWrapper
    private let getTopicGroupPushWarpper: (TopicGroup) throws -> TopicGroupPushWrapper

    private func addObservers() {
        self.disposeBag = DisposeBag()
        // 监听是否展示入群申请Banner
        self.chatWrapper?.chat.distinctUntilChanged { $0.showApplyBadge == $1.showApplyBadge }
            .subscribe(onNext: { [weak self](chat) in
                guard let `self` = self,
                      !chat.isMeeting else { return }
                self.badgeShow(for: self.settingPath, show: chat.showApplyBadge)
            }).disposed(by: disposeBag)
        // 如果当前不处于观察者模式，则监听Pin红点 & Todo红点
        if !(topicGroup?.isParticipant ?? false) {
            let pinPath = self.pinPath
            self.pinAPI?
                .getPinReadStatus(chatId: self.chatID).subscribe(onNext: { [weak self] (hasRead) in
                    self?.badgeShow(for: pinPath, show: !hasRead)
                }).disposed(by: self.disposeBag)

            self.pinReadStatusObservable
                .filter({ [weak self] (push) -> Bool in
                    return push.chatId == self?.chatID ?? ""
                })
                .subscribe(onNext: { [weak self] (push) in
                    self?.badgeShow(for: pinPath, show: !push.hasRead)
            }).disposed(by: self.disposeBag)
        }
        self.observerTopNotice()
    }

    ///监听置顶的变化
    private func observerTopNotice() {
        if let chat = self.chat, topNoticeService?.isSupportTopNoticeChat(chat) ?? false {
            topNoticeDataManger.startGetAndObserverTopNoticeData()
        }
    }

    func preloadDocFeed(_ url: String, from source: String) {
        dependency.preloadDocFeed(url, from: source)
    }
}

// MARK: - 路由
extension ThreadContainerViewModel {
    private var chatidPath: Path { return Path().prefix(Path().chat_id, with: chatID) }

    private var charMorePath: Path { return chatidPath.chat_more }

    private var settingPath: Path { return charMorePath.raw(SidebarItemType.setting.rawValue) }

    private var pinPath: Path { return charMorePath.raw(SidebarItemType.pin.rawValue) }

    /// 控制Badge显示
    ///
    /// - Parameters:
    ///   - path: Badge路径
    ///   - show: 是否显示
    private func badgeShow(for path: Path, show: Bool, type: LarkBadge.BadgeType = .dot(.pin)) {
        if show {
            BadgeManager.setBadge(path, type: type)
        } else {
            BadgeManager.clearBadge(path)
        }
    }
}
