//
//  MockFeedAPIBaseImpl.swift
//  LarkMessengerDemoMockFeeds
//
//  Created by bytedance on 2020/5/18.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkSDKInterface
import RxSwift
import LarkModel

/*
 各UI test case对应的MockFeedAPI实例，均继承于此类，然后override掉test case所需要的方法
 */
class MockFeedAPIBaseImpl: MockFeedAPI {
    // 调试专用，便于识别被触发的接口函数
    static let tag = "MOCKFEEDS_BASE"

    // Mock feeds required - 能从该API拉取到的各种类型Feeds的总数
    let maxFeedsLimit: Int

    // 能获取到的Shortcuts的数量
    let maxShortcutsLimit: Int

    // 始终记录生产过的feeds count，由小到大
    var curFeedIndex = 0

    // 记录发出的所有Feeds，供其他联调调用 - 仅限于使用 getFeedCardsWithGenerator 生成的feeds
    var feedsGenerated = [FeedCardPreview]()

    // MARK: MockFeedAPI stubs only

    // part of FeedAPI protocol
    var websocketStatusPush: Observable<PushWebSocketStatus>

    required init(webSocketStatusPushOb: Observable<PushWebSocketStatus>,
                  maxFeedsLimit: Int,
                  maxShortcutsLimit: Int) {
        self.websocketStatusPush = webSocketStatusPushOb
        self.maxFeedsLimit = maxFeedsLimit
        self.maxShortcutsLimit = maxShortcutsLimit
    }

    // MARK: MockFeedAPI protocol stubs
    // LH 可以通过观察日志中输出的log tag来判断是否有哪些接口需要提供测试数据，来进一步完善覆盖度

    func triggerSyncData() -> Observable<Void> {
        print("\(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function)")
        return stubFunction()
    }

    func getFeedCards(feedType: FeedCard.FeedType,
                      pullType: FeedPullType,
                      feedCardID: String?,
                      cursor: Int,
                      count: Int) -> Observable<GetFeedCardsResult> {
        print("""
              \(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function)
              - feedType: \(feedType) - pullType: \(pullType) - feedCardID: \(feedCardID ?? "NIL")
              - cursor: \(cursor) - count: \(count)
              """)
        return stubFunction()
    }

    func moveToDone(feedId: String, entityType: FeedCard.EntityType) -> Observable<Void> {
        print("\(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function) - feedId: \(feedId) - entityType: \(entityType)")
        return stubFunction()
    }

    func loadShortcuts(preCount: Int) -> Observable<FeedContextResponse> {
        print("\(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function) - preCount: \(preCount)")
        return stubFunction()
    }

    func createShortcuts(_ shortcuts: [Shortcut]) -> Observable<Void> {
        print("\(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function) - shortcuts.count: \(shortcuts.count)")
        return stubFunction()
    }

    func deleteShortcuts(_ shortcuts: [Shortcut]) -> Observable<Void> {
        print("\(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function) - shortcuts.count: \(shortcuts.count)")
        return stubFunction()
    }

    func setFeedCardsIntoBox(feedCardId: String) -> Observable<String> {
        print("\(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function) - feedCardId: \(feedCardId)")
        return stubFunction()
    }

    func deleteFeedCardsFromBox(feedCardId: String, isRemind: Bool) -> Observable<Void> {
        print("""
              \(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function)
              - feedCardId: \(feedCardId) - isRemind: \(isRemind)
              """)
        return stubFunction()
    }

    func update(shortcut: Shortcut, newPosition: Int) -> Observable<Void> {
        print("""
              \(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function)
              - shortcut: \(shortcut.debugDescription) - newPosition: \(newPosition)
              """)
        return stubFunction()
    }

    func computeDoneUnreadBadge() -> Observable<ComputeDoneCardsResponse> {
        print("\(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function)")
        return stubFunction()
    }

    func pushHideChannel(channel: Channel) -> Observable<Void> {
        print("\(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function) - channel: \(channel)")
        return stubFunction()
    }

    func peakFeedCard(by id: String, entityType: FeedCard.EntityType) -> Observable<Void> {
        print("\(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function) - id: \(id) - entityType: \(entityType)")
        return stubFunction()
    }

    func preloadFeedCards(by ids: [String]) -> Observable<Void> {
        print("\(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function) - ids: \(ids.debugDescription)")
        return stubFunction()
    }

    func markFeedCard(_ id: String, isDelayed: Bool) -> Observable<FeedCardPreview> {
        print("\(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function) - id: \(id) - isDelayed: \(isDelayed)")
        return stubFunction()
    }

    func getDelayedFeedCards() -> Observable<[FeedCardPreview]> {
        print("\(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function)")
        return stubFunction()
    }

    func setFeedCardFilter(_ filter: FeedCardFilter) -> Observable<Void> {
        print("\(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function) - filter: \(filter)")
        return stubFunction()
    }

    func getNextUnreadFeedCardsBy(_ id: String?) -> Observable<NextUnreadFeedCardsResult> {
        print("\(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function) - id: \(id ?? "NIL")")
        return stubFunction()
    }

    func putUserColdBootRequest() -> Observable<Void> {
        print("\(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function)")
        return stubFunction()
    }

    func cleanNewBoxFeedCards(isNoticeHidden: Bool) -> Observable<Void> {
        print("\(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function) - isNoticeHidden: \(isNoticeHidden)")
        return stubFunction()
    }

    func getNewBoxFeedCards() -> Observable<[FeedCardPreview]> {
        print("\(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function)")
        return stubFunction()
    }

    func setAppNotificationRead(appID: String, seqID: String) -> Observable<Void> {
        print("\(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function) - appID: \(appID) - seqID: \(seqID)")
        return stubFunction()
    }

    func changeOpenAppFeedRequest(appID: String, seqID: String) -> Observable<Void> {
        print("\(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function) - appID: \(appID) - seqID: \(seqID)")
        return stubFunction()
    }

    func setFeedPushSubscription(_ on: Bool, for scene: FeedPushScene) -> Observable<Void> {
        print("\(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function) - on: \(on) - scene: \(scene)")
        return stubFunction()
    }

    func removeFeedCard(channel: Channel, feedType: FeedCard.EntityType?) -> Observable<Void> {
        print("\(MockFeedAPIBaseImpl.tag) - \(#file) - \(#function) - channel: \(channel) - feedType: \(feedType)")
        return stubFunction()
    }

    // MARK: Private functions
    private func stubFunction<T>() -> Observable<T> {
        Observable<T>.create { _ in Disposables.create() }
    }
}
