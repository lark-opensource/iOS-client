//
//  TopUnReadThreadsTipViewModel.swift
//  LarkThread
//
//  Created by zc09v on 2019/2/25.
//

import Foundation
import RxCocoa
import RxSwift
import LarkCore
import LarkMessageCore
import LarkModel
import LarkSDKInterface
import LKCommonsLogging
import LarkFeatureGating
import LarkContainer
import RustPB

/// doc: https://bytedance.feishu.cn/wiki/wikcn0PuncoL4xaMKG61tqW3XUh#QdfgwD
/// 暂时参考chat的电梯文档，后续补充 @TODO: @zhaodong
final class UnReadOldThreadsTipViewModel: BaseUnreadMessagesTipViewModel {
    private static let threadLogger = Logger.log(UnReadOldThreadsTipViewModel.self, category: "LarkThread")
    private let readPositionBadgeCount: Int32
    private var minReadPositionBadgeCount: Int32?
    private let threadAPI: ThreadAPI
    private let chatID: String
    private var preloadMessagePosition: Int32?
    private let requestCount: Int32
    private let redundancyCount: Int32
    private lazy var unreadAtMessages: [ThreadMessage] = []

    init(
        userResolver: UserResolver,
        chatID: String,
        firstUnreadMessagePosition: Int32?,
        readPositionBadgeCount: Int32,
        requestCount: Int32,
        redundancyCount: Int32,
        threadAPI: ThreadAPI) {
        self.readPositionBadgeCount = readPositionBadgeCount
        self.threadAPI = threadAPI
        self.chatID = chatID
        self.preloadMessagePosition = firstUnreadMessagePosition
        self.requestCount = requestCount
        self.redundancyCount = redundancyCount
        super.init(userResolver: userResolver)
        observeState()
    }

    override func fetchDataWhenLoad() {
        if let preloadMessagePosition = preloadMessagePosition {
            self.preloadThreads(position: preloadMessagePosition,
                                type: .fetchData).subscribe().disposed(by: self.disposeBag)
            self.preloadMessagePosition = nil
        }
        fetchUnreadAtMessages()
    }

    public func updateThreadRead(badgeCount: Int32, position: Int32) {
        self.dataQueue.async { [weak self] in
            guard self?.update(badgeCount) ?? false else {
                return
            }
            self?.changeState(badgeCount: badgeCount, position: position)
        }
    }

    private func changeState(badgeCount: Int32, position: Int32) {
        if badgeCount <= self.readPositionBadgeCount {
            self.state.accept(.dismiss)
        } else {
            // 如果是atall，并且当前滚到了是atall的消息，清除缓存并消除atAll
            if case .showUnReadAt = self.state.value, self.unreadAtMessages.contains(where: { $0.position == position }) {
                self.unreadAtMessages.removeAll(where: { $0.position == position })
                self.state.accept(.dismiss)
            }
            // 判断是否还有剩余的atAll
            for unreadAtMessage in unreadAtMessages where
                (unreadAtMessage.badgeCount >= self.readPositionBadgeCount &&
                    unreadAtMessage.position < position) {
                self.state.accept(.showUnReadAt(unreadAtMessage, position))
                return
            }
            let count = badgeCount - self.readPositionBadgeCount
            Self.logger.info("lark thread TopUnReadThreadsTipViewModel  showUnReadMessages badgeCount: \(badgeCount), readPositionBadgeCount \(self.readPositionBadgeCount)")
            self.state.accept(.showUnReadMessages(count, position))
        }
    }

    // 监听状态变化，提前预加载数据
    private func observeState() {
        self.state
            .distinctUntilChanged { (state1, state2) -> Bool in
                return state1 == state2
            }.flatMap { [weak self] (state) -> Observable<Void> in
                guard let self = self else { return .empty() }
                switch state {
                case .showUnReadAt(_, let position):
                    return self.preloadThreads(position: position, type: .showUnReadAt)
                default:
                    return .empty()
                }
            }.subscribe().disposed(by: self.disposeBag)
    }

    private func fetchUnreadAtMessages() {
        var quary = GetUnreadAtMessagesRequestQuary()
        quary.chatID = Int64(chatID) ?? 0
        quary.atType = .all
        threadAPI.fetchUnreadAtMessages(quaries: quary, ignoreBadged: false, needResponse: true)
            .observeOn(self.dataScheduler)
            .subscribe(onNext: { [weak self] (unreadAtMessages) in
                self?.unreadAtMessages = unreadAtMessages.sorted(by: { (msg1, msg2) -> Bool in
                    return msg1.position > msg2.position
                })
                let unreadAtMessages = (self?.unreadAtMessages ?? [])
                switch self?.state.value ?? .dismiss {
                case .dismiss, .showToLastMessage:
                    break
                case .showUnReadAt(let currentUnReadAtMsg, let minReadPosition):
                    for unreadAtMessage in unreadAtMessages where
                        (unreadAtMessage.badgeCount >= self?.readPositionBadgeCount ?? -1 &&
                            unreadAtMessage.position < minReadPosition &&
                            unreadAtMessage.position > currentUnReadAtMsg.position) {
                        self?.state.accept(.showUnReadAt(unreadAtMessage, minReadPosition))
                        return
                    }
                case .showUnReadMessages(_, let minReadPosition):
                    for unreadAtMessage in unreadAtMessages where
                        (unreadAtMessage.badgeCount >= self?.readPositionBadgeCount ?? -1 &&
                            unreadAtMessage.position < minReadPosition) {
                        self?.state.accept(.showUnReadAt(unreadAtMessage, minReadPosition))
                        return
                    }
                }
            }).disposed(by: disposeBag)
    }

    // 记录当前最顶部的message，只更新更顶部的message
    private func update(_ newPositionBadgeCount: Int32) -> Bool {
        if let minReadPositionBadgeCount = self.minReadPositionBadgeCount {
            if newPositionBadgeCount < minReadPositionBadgeCount {
                self.minReadPositionBadgeCount = newPositionBadgeCount
                return true
            } else {
                return false
            }
        } else {
            self.minReadPositionBadgeCount = newPositionBadgeCount
            return true
        }
    }

    // MARK: - fetch data
    private func preloadThreads(position: Int32, type: PreloadThreadsType) -> Observable<Void> {
        var channel = RustPB.Basic_V1_Channel()
        channel.id = chatID
        channel.type = .chat
        Self.logger.info("preloadThreads track UnReadNewThreadsTipViewModel \(type.rawValue) chatId:\(self.chatID) position \(position)")
        return self.threadAPI.fetchThreads(
            channel: channel,
            scene: .specifiedPosition(position),
            redundancyCount: redundancyCount,
            count: requestCount,
            needReplyPrompt: false
        ).map({ (_) -> Void in return })
    }

    override func unReadTip(count: Int32) -> String {
        return count == 1 ? BundleI18n.LarkThread.Lark_TopicChannel_OneNewTopicIOS : BundleI18n.LarkThread.Lark_TopicChannel_XNewTopicIOS
    }
}
