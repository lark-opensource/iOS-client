//
//  MockTabFeedsViewModelDependency.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/9/7.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import XCTest
import RustPB
import RxSwift
import LarkSDKInterface
import SwiftProtobuf
import LarkMessengerInterface
import RxRelay
import LarkAccountInterface
@testable import LarkFeed

// swiftlint:disable all
class MockTabFeedsViewModelDependency: TabFeedsViewModelDependency {
    // 为了不同的test case能定制不同的dependency返回值，这里支持builder
    var loadMissingByCursorEnabledBuilder: (() -> Bool)?

    var getFeedCardsBuilder: ((_ feedType: Basic_V1_FeedCard.FeedType,
                            _ pullType: FeedPullType,
                            _ feedCardID: String?,
                            _ cursor: Int,
                            _ count: Int) -> Observable<GetFeedCardsResult>)?

    var setFeedCardFilterBuilder: ((_ filter: FeedCardFilter) -> Observable<Void>)?

    var loadAllBuilder: (() -> Void)?

    var updateFeedCountBuilder: ((_ feedsCount: Int) -> Void)?

    func sendAsyncRequest(_ request: Message) -> Observable<[String: String]> {
        // 为了和sdk返回值区分，这里故意取+10的值
        let setting = LoadSetting(buffer: 60, cache_total: 110, loadmore: 60, refresh: 30)
        let data = try! JSONEncoder().encode(setting)
        let str = String(data: data, encoding: .utf8)
        let res = ["messenger_feed_load_count": str!]
        return .just(res)
    }

    var is24HourTime: BehaviorRelay<Bool> {
        return .init(value: true)
    }

    var feedPreviewObservable: Observable<PushFeedPreview> {
        return .empty()
    }

    var threadFeedAvatarChangesObservable: Observable<PushThreadFeedAvatarChanges> {
        .empty()
    }

    var badgeStyleObservable: Observable<Settings_V1_BadgeStyle> {
        .empty()
    }

    var feedCursorObservable: Observable<Feed_V1_PushFeedCursor> {
        .empty()
    }

    func getFeedCards(feedType: Basic_V1_FeedCard.FeedType, pullType: FeedPullType, feedCardID: String?, cursor: Int, count: Int) -> Observable<GetFeedCardsResult> {
        return getFeedCardsBuilder!(feedType, pullType, feedCardID, cursor, count)
    }

    func getFeedCards(feedType: Basic_V1_FeedCard.FeedType, pullType: FeedPullType, maxCursor: Int, minCursor: Int) -> Observable<GetFeedCardsResult> {
        var feedCard = buildFeedPreview()
        feedCard.id = "2"
        feedCard.rankTime = 200
        feedCard.type = .chat
        feedCard.feedType = .inbox
        var cursor = Feed_V1_Cursor()
        cursor.maxCursor = Int64(maxCursor)
        cursor.minCursor = Int64(minCursor)
        let res = GetFeedCardsResult(feeds: [feedCard], nextCursor: 10, cursors: [cursor], timeCost: 0)
        return .just(res)
    }

    func getNextUnreadFeedCardsBy(_ id: String?) -> Observable<NextUnreadFeedCardsResult> {
        let feed = buildFeedPreview()
        let cursor = Feed_V1_Cursor()
        let res = NextUnreadFeedCardsResult(previews: [feed],
                                            nextCursor: 0,
                                            continuousCursors: [cursor])
        return .just(res)
    }

    func setFeedCardFilter(_ filter: FeedCardFilter) -> Observable<Void> {
        return setFeedCardFilterBuilder!(filter)
    }

    func getAndReviseBadgeStyle() -> (Observable<Settings_V1_BadgeStyle>, Observable<Settings_V1_BadgeStyle>) {
        (.just(.strongRemind), .just(.strongRemind))
    }

    func computeDoneUnreadBadge() -> Observable<Feed_V1_ComputeDoneCardsResponse> {
        let response = Feed_V1_ComputeDoneCardsResponse()
        return .just(response)
    }

    func newMeeting(from: UIViewController) {
    }

    func joinMeeting(from: UIViewController) {
    }

    func pushCreateDoc(from: UIViewController) {
    }

    func dynamicMemberInvitePageResource(baseView: UIView?, sourceScenes: MemberInviteSourceScenes, departments: [String]) -> Observable<ExternalDependencyBodyResource> {
        let body = MemberInviteSplitBody(sourceScenes: .contact)
        return .just(.memberFeishuSplit(body))
    }

    func handleInviteEntryRoute(routeHandler: @escaping (InviteEntryType) -> Void) {
    }

    func needShowGuide(key: String) -> Bool {
        false
    }

    func didShowGuide(key: String) {
    }

    var loadMissingByCursorEnabled: Bool {
        loadMissingByCursorEnabledBuilder!()
    }

    func triggerSyncData() -> Observable<Void> {
        .just(())
    }
}
// swiftlint:enable all
