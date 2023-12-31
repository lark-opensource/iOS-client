//
// Created by bytedance on 2020/6/3.
// Copyright (c) 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkSDKInterface
import RxSwift
import LarkModel
import RustPB
import LarkRustClient
import ThreadSafeDataStructure

class UltimateScenarioMockFeedAPI: MockFeedAPIBaseImpl {
    /// 置顶数据：需要加读写锁
    private var shortcuts: SafeArray<ShortcutResult> = [] + .readWriteLock

    /// Inbox Feed: 需要加读写锁
    private var inboxFeed: SafeArray<FeedCardPreview> = [] + .readWriteLock
    /// 当前已返回的Inbox Feed Count
    private var inboxIndex = 0

    // 终止Timer
    private var updateCount = 0
    private var refreshCount = 0
    private let maxCount = 10_000

    required init(webSocketStatusPushOb: Observable<PushWebSocketStatus>,
                  maxFeedsLimit: Int,
                  maxShortcutsLimit: Int) {
        super.init(webSocketStatusPushOb: webSocketStatusPushOb,
                   maxFeedsLimit: maxFeedsLimit,
                   maxShortcutsLimit: maxShortcutsLimit)
        self.buildInboxFeed()
        self.buildShortcuts()
    }

    /// Mock Push
    override func putUserColdBootRequest() -> Observable<Void> {
        let ret = super.putUserColdBootRequest()

        // 给一个Push，刷新出稍后处理Item：时机较早，需要async
        DispatchQueue.main.async {
            let delayedCount = Int32(self.inboxFeed.filter({ $0.isDelayed }).count)
            let message = FeedPreviewResponse(delayedChannelCount: delayedCount)
            MockFeedPreviewPushGenerator.shared.post(message: message)
        }

        // 模拟Feed频繁更新：为了方便观察，都只更新前两条
        let updateTimer = Timer(timeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self,
                self.updateCount <= self.maxCount,
                self.inboxFeed.count >= 3 else { // index校验
                timer.invalidate()
                return
            }
            self.updateCount += 1

            // index = 0是boxFeed
            // count奇偶反转，导致feedFirst和feedSecond rankTime反转
            let time = Int64(NSDate().timeIntervalSince1970)
            var feedFirst = self.inboxFeed[1]
            feedFirst.unreadCount += 1
            feedFirst.localizedDigestMessage = "New First \(self.updateCount)"
            feedFirst.displayTime = ((self.updateCount & 1 == 1) ? time : time + 100)
            feedFirst.rankTime = feedFirst.displayTime
            feedFirst.updateTime = feedFirst.displayTime
            self.inboxFeed[1] = feedFirst

            var feedSecond = self.inboxFeed[2]
            feedSecond.unreadCount += 1
            feedSecond.localizedDigestMessage = "New Second \(self.updateCount)"
            feedSecond.displayTime = ((self.updateCount & 1 == 1) ? time + 100 : time)
            feedSecond.rankTime = feedSecond.displayTime
            feedSecond.updateTime = feedSecond.displayTime
            self.inboxFeed[2] = feedSecond

            let delayedCount = Int32(self.inboxFeed.filter({ $0.isDelayed }).count)
            let message = FeedPreviewResponse(updatePreviews: [feedFirst, feedSecond],
                                              delayedChannelCount: delayedCount)
            MockFeedPreviewPushGenerator.shared.post(message: message)
        }

        RunLoop.main.add(updateTimer, forMode: .common)

        // 模拟Feed增加/删除：奇偶反转，增删同一Feed
        let refreshTimer = Timer(timeInterval: 10, repeats: true) { [weak self] timer in
            guard let self = self,
                self.refreshCount <= self.maxCount else {
                    timer.invalidate()
                    return
            }
            self.refreshCount += 1

            let feedId = "999999999999999999"
            if self.refreshCount & 1 == 1 {
                var feed = MockFeedsGenerator.getRandomFeed(.inbox, 0)
                feed.avatarKey = "834e000a1c1e7e1d71df"  // 暂时复用固定的avatarKey
                feed.name = "Insert Feed"
                feed.chatType = .p2P
                feed.chatRole = .member  // 如果是其他role，就会触发 HideChannelAlert
                feed.entityStatus = Bool.random() ? .read : .unread  // 仅支持这两种状态
                feed.parentCardID = "0"
                feed.pair = MockFeedsGenerator.getRandomPairWithType(.chat)
                feed.chatMode = .threadV2 // 为了Feed可点击，固定设置为thread，不然进群时会crash
                feed.isShortcut = false
                feed.isDelayed = false
                feed.pair.id = feedId
                feed.localizedDigestMessage = "Desc \(feedId)"
                self.inboxFeed.append(feed)
                let delayedCount = Int32(self.inboxFeed.filter({ $0.isDelayed }).count)
                let message = FeedPreviewResponse(updatePreviews: [feed],
                                                  delayedChannelCount: delayedCount)
                MockFeedPreviewPushGenerator.shared.post(message: message)
            } else {
                var inboxFeed = self.inboxFeed.getImmutableCopy()
                if let index = inboxFeed.firstIndex(where: { $0.pair.id == feedId }) {
                    let feed = inboxFeed.remove(at: index)
                    self.inboxFeed.replaceInnerData(by: inboxFeed)
                    let delayedCount = Int32(self.inboxFeed.filter({ $0.isDelayed }).count)
                    let message = FeedPreviewResponse(removePreviews: [feed],
                                                      delayedChannelCount: delayedCount)
                    MockFeedPreviewPushGenerator.shared.post(message: message)
                }
            }
        }
        RunLoop.main.add(refreshTimer, forMode: .common)

        return ret
    }

    /// 拉取Shortcut
    override func loadShortcuts(preCount: Int) -> Observable<FeedContextResponse> {
        _ = super.loadShortcuts(preCount: preCount)

        return Observable<FeedContextResponse>.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            observer.onNext((self.shortcuts.getImmutableCopy(), "UltimateScenario_Load_Shortcut"))
            return Disposables.create()
        }
    }

    /// 拉取Feed
    override func getFeedCards(feedType: FeedCard.FeedType,
                               pullType: FeedPullType,
                               feedCardID: String?,
                               cursor: Int,
                               count: Int) -> Observable<GetFeedCardsResult> {
        _ = super.getFeedCards(feedType: feedType,
                               pullType: pullType,
                               feedCardID: feedCardID,
                               cursor: cursor,
                               count: count)

        // feedCardID != nil: 拉取会话盒子内feed
        if let feedCardID = feedCardID {
            return getBoxFeedCards(feedType: feedType,
                                   pullType: pullType,
                                   feedCardID: feedCardID,
                                   cursor: cursor,
                                   count: count)
        }

        assert(feedType != .done, "不能切换到Done Filter，因为从Done切换到Inbox不会触发此方法，没有时机重置index")

        return getInBoxFeedCards(feedType: feedType,
                                 pullType: pullType,
                                 feedCardID: feedCardID,
                                 cursor: cursor,
                                 count: count)
    }

    // 取消置顶
    override func deleteShortcuts(_ shortcuts: [Shortcut]) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            // 此处默认取消置顶成功，不再模拟断网情况下取消置顶失败的情况
            observer.onNext(())
            // pushFeedPreviewOb更新Feed置顶状态
            self.updateFeed(by: shortcuts, isShortcut: false)
            // pushShortcutsOb更新置顶
            self.updateShortcut(shortcuts: shortcuts, isShortcut: false)
            return Disposables.create()
        }
    }

    // 添加置顶
    override func createShortcuts(_ shortcuts: [Shortcut]) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            // 此处默认置顶成功，不再模拟断网情况下置顶失败的情况
            observer.onNext(())
            // pushFeedPreviewOb更新Feed
            self.updateFeed(by: shortcuts, isShortcut: true)
            // pushShortcutsOb更新置顶
            self.updateShortcut(shortcuts: shortcuts, isShortcut: true)
            return Disposables.create()
        }
    }

    /// 稍后处理
    override func markFeedCard(_ id: String, isDelayed: Bool) -> Observable<FeedCardPreview> {
        return Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            // 此处默认稍后处理成功，不再模拟断网情况下稍后处理失败的情况
            if var feed = self.inboxFeed.first(where: { $0.pair.id == id }),
                let index = self.inboxFeed.firstIndex(where: { $0.pair.id == id }) {
                observer.onNext(feed)
                // 发送更新push给pushFeedPreviewOb更新Feed和StatusView
                feed.isDelayed = isDelayed
                self.inboxFeed[index] = feed
                let delayedCount = Int32(self.inboxFeed.filter({ $0.isDelayed }).count)
                let message = FeedPreviewResponse(updatePreviews: [feed],
                                                  delayedChannelCount: delayedCount)
                MockFeedPreviewPushGenerator.shared.post(message: message)
            } else {
                let err = NSError(domain: "Match No FeedCardPreview", code: -1, userInfo: nil)
                observer.onError(err)
            }
            return Disposables.create()
        }
    }

    /// Move To Done
    override func moveToDone(feedId: String, entityType: FeedCard.EntityType) -> Observable<Void> {
        // 删除inbox数据源
        var inboxFeed = self.inboxFeed.getImmutableCopy()
        if let index = inboxFeed.firstIndex(where: { $0.pair.id == feedId }) {
            let preview = inboxFeed.remove(at: index)
            self.inboxFeed.replaceInnerData(by: inboxFeed)
            // 如果该Feed是稍后处理，需Push更新稍后处理
            let delayedCount = Int32(inboxFeed.filter({ $0.isDelayed }).count)
            let message = FeedPreviewResponse(removePreviews: [preview],
                                              delayedChannelCount: delayedCount)
            MockFeedPreviewPushGenerator.shared.post(message: message)
        }
        return super.moveToDone(feedId: feedId, entityType: entityType)
    }

}

// MARK: Private Method
extension UltimateScenarioMockFeedAPI {
    /// 拉取会话盒子Feed
    private func getBoxFeedCards(feedType: FeedCard.FeedType,
                                 pullType: FeedPullType,
                                 feedCardID: String?,
                                 cursor: Int,
                                 count: Int) -> Observable<GetFeedCardsResult> {

        return Observable<GetFeedCardsResult>.create { [weak self] observer in
            guard let self = self,
                let boxFeed = self.inboxFeed.first(where: { $0.pair.type == .box }) else {
                return Disposables.create()
            }
            var feeds = [FeedCardPreview]()
            for i in 0..<50 {
                var feed = MockFeedsGenerator.getRandomFeed(.inbox, i)
                feed.avatarKey = "834e000a1c1e7e1d71df"  // 暂时复用固定的avatarKey
                feed.name = "Box Feed #\(i)"
                feed.chatType = .p2P
                feed.chatRole = .member  // 如果是其他role，就会触发 HideChannelAlert
                feed.entityStatus = Bool.random() ? .read : .unread  // 仅支持这两种状态
                feed.parentCardID = boxFeed.pair.id
                feed.pair = MockFeedsGenerator.getRandomPairWithType(.chat)
                feeds.append(feed)
            }

            // 根据feeds计算有效CursorPair
            let cursorPair = MockFeedsGenerator.getCursorPairForFeeds(feeds)
            // 会话盒子这里无法mock加载更多feed，因为没有时机重置会话盒子的index，所以mock拉一次结束
            let ret = GetFeedCardsResult(feeds: feeds, nextCursor: 0, cursors: [cursorPair])

            observer.onNext(ret)
            return Disposables.create()
        }
    }

    /// 拉取Inbox Feed
    private func getInBoxFeedCards(feedType: FeedCard.FeedType,
                                   pullType: FeedPullType,
                                   feedCardID: String?,
                                   cursor: Int,
                                   count: Int) -> Observable<GetFeedCardsResult> {
        // 返回给客户端小于等于count个feeds
        let feedsToReturn = min(maxFeedsLimit - inboxIndex, count)

        // 如果达到生成feeds的上限，就返回结束状态, 让APP中的加载递归停止
        if feedsToReturn <= 0 {
            return getFeedCardsReachEnd()
        }

        return Observable<GetFeedCardsResult>.create { [weak self] observer in
            guard let self = self else {
                return Disposables.create()
            }
            let inboxFeed = self.inboxFeed.getImmutableCopy()
            let feeds = Array(inboxFeed[self.inboxIndex..<(feedsToReturn + self.inboxIndex)])
            self.inboxIndex += feedsToReturn
            print("@HusterYP inboxIndex: \(self.inboxIndex)")

            // 根据feeds计算有效CursorPair
            let cursorPair = MockFeedsGenerator.getCursorPairForFeeds(feeds)
            let ret = GetFeedCardsResult(feeds: feeds, nextCursor: Int(cursorPair.minCursor) - 1, cursors: [cursorPair])

            // TODO: 拉满100个后延迟

            observer.onNext(ret)
            return Disposables.create()
        }
    }

    /// Feed置顶状态改变
    private func updateFeed(by shortcuts: [Shortcut], isShortcut: Bool) {
        // pushFeedPreviewOb更新Feed
        let feeds = self.inboxFeed.filter { (feed) -> Bool in
            return shortcuts.contains(where: { $0.channel.id == feed.pair.id })
        }.compactMap { (feed) -> FeedCardPreview? in
            var feed = feed
            feed.isShortcut = isShortcut
            return feed
        }

        // 更新数据源
        feeds.forEach { (feed) in
            if let index = self.inboxFeed.firstIndex(where: { $0.pair.id == feed.pair.id }) {
                self.inboxFeed[index] = feed
            }
        }

        let delayedCount = Int32(self.inboxFeed.filter({ $0.isDelayed }).count)
        let message = FeedPreviewResponse(updatePreviews: feeds,
                                          delayedChannelCount: delayedCount)
        MockFeedPreviewPushGenerator.shared.post(message: message)
    }

    /// 置顶改变
    private func updateShortcut(shortcuts: [Shortcut], isShortcut: Bool) {
        // create shortcut
        if isShortcut {
            let res = shortcuts.compactMap { (shortcut) -> ShortcutResult? in
                guard let preview = self.inboxFeed.first(where: { $0.pair.id == shortcut.channel.id }) else {
                    return nil
                }
                return ShortcutResult(shortcut: shortcut, preview: preview)
            }
            self.shortcuts.append(contentsOf: res)
        } else {
            // delete shortcut
            var old = self.shortcuts.getImmutableCopy()
            old.removeAll { (res) -> Bool in
                return shortcuts.contains(where: { $0.channel.id == res.shortcut.channel.id })
            }
            self.shortcuts.replaceInnerData(by: old)
        }
        // 发送push
        var message = Feed_V1_PushShortcutsResponse()
        message.shortcuts = self.shortcuts.compactMap({ $0.shortcut })
        var previews = [String: FeedCardPreview]()
        self.shortcuts.forEach({ previews[$0.shortcut.channel.id] = $0.preview })
        message.previews = previews

        MockInterceptionManager.shared.postMessage(command: .pushShortcuts, message: message)
    }
}

// MARK: 构造初始数据
extension UltimateScenarioMockFeedAPI {
    /// 构建初始置顶数据
    private func buildShortcuts() {
        let start = CFAbsoluteTimeGetCurrent()

        var shortcuts = [ShortcutResult]()
        for i in 0..<self.maxShortcutsLimit {
            var shortcut = Shortcut()
            shortcut.position = Int32(i)
            shortcut.channel.type = .chat

            let preview = inboxFeed[i + 1]
            shortcut.channel.id = preview.pair.id

            let result = ShortcutResult(shortcut: shortcut, preview: preview)
            shortcuts.append(result)
        }

        let end = CFAbsoluteTimeGetCurrent()
        print("@HusterYP: buildShortcuts time = \((end - start) * 1000) ms")
        self.shortcuts.append(contentsOf: shortcuts)
    }

    /// 构建初始Inbox数据：会话盒子 + Chat Feed
    private func buildInboxFeed() {
        let start = CFAbsoluteTimeGetCurrent()

        var feeds = [FeedCardPreview]()
        // 构造一条会话盒子数据
        var boxFeed = MockFeedsGenerator.getRandomFeed(.inbox, 0)
        boxFeed.pair = MockFeedsGenerator.getRandomPairWithType(.box)
        boxFeed.parentCardID = "0"
        boxFeed.chatRole = .member
        boxFeed.isDelayed = false
        boxFeed.isShortcut = false
        boxFeed.pair.id = "999999"
        feeds.append(boxFeed)

        // 剩下的构建chat feed：前maxShortcutsLimit个为置顶和稍后处理数据
        for i in 1..<self.maxFeedsLimit {
            var feed = MockFeedsGenerator.getRandomFeed(.inbox, i)
            feed.avatarKey = "834e000a1c1e7e1d71df"  // 暂时复用固定的avatarKey
            feed.name = (i <= maxShortcutsLimit ? "\(i)#Shortcut" : "Chat Inbox #\(i)")
            feed.chatType = .p2P
            feed.chatRole = .member  // 如果是其他role，就会触发 HideChannelAlert
            feed.entityStatus = Bool.random() ? .read : .unread  // 仅支持这两种状态
            feed.parentCardID = "0"
            feed.pair = MockFeedsGenerator.getRandomPairWithType(.chat)
            feed.chatMode = .threadV2 // 为了Feed可点击，固定设置为thread，不然进群时会crash
            feed.isShortcut = (i <= maxShortcutsLimit ? true : false)
            feed.isDelayed = (i <= maxShortcutsLimit ? true : false)
            feed.pair.id = "\(i)"
            feed.localizedDigestMessage = "Desc \(i)"
            feeds.append(feed)
        }

        let end = CFAbsoluteTimeGetCurrent()
        print("@HusterYP: buildInboxFeed time = \((end - start) * 1000) ms")
        self.inboxFeed.append(contentsOf: feeds)
    }
}
