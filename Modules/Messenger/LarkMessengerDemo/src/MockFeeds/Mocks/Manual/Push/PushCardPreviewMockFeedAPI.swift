//
//  PushCardPreviewMockFeedAPI.swift
//  LarkMessengerDemoMockFeeds
//
//  Created by 袁平 on 2020/5/24.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkModel
import LarkFeed
import RustPB
import LarkRustClient
import RxSwift

struct FeedPreviewResponse {
    let updatePreviews: [FeedCardPreview]
    let removePreviews: [FeedCardPreview]
    let unreadCount: Int32
    let filteredUnreadCount: Int32
    let filteredMuteUnreadCount: Int32
    let delayedChannelCount: Int32

    init(updatePreviews: [FeedCardPreview] = [],
         removePreviews: [FeedCardPreview] = [],
         unreadCount: Int32 = 0,
         filteredUnreadCount: Int32 = 0,
         filteredMuteUnreadCount: Int32 = 0,
         delayedChannelCount: Int32 = 0) {
        self.updatePreviews = updatePreviews
        self.removePreviews = removePreviews
        self.unreadCount = unreadCount
        self.filteredUnreadCount = filteredUnreadCount
        self.filteredMuteUnreadCount = filteredMuteUnreadCount
        self.delayedChannelCount = delayedChannelCount
    }
}

/// FeedCardPreviewsPushHandler Mock
class MockFeedPreviewPushGenerator {
    static let shared = MockFeedPreviewPushGenerator()

    func post(message: FeedPreviewResponse) {
        var response = PushInboxCardsResponse()
        var updatePreviews: [String: FeedCardPreview] = [:]
        message.updatePreviews.forEach({ updatePreviews[$0.pair.id] = $0 })
        response.updatePreviews = updatePreviews
        response.removePreviews = message.removePreviews.compactMap({ $0.pair })
        response.unreadCount = message.unreadCount
        response.filteredUnreadCount = message.filteredUnreadCount
        response.filteredMuteUnreadCount = message.filteredMuteUnreadCount
        response.delayedChannelCount = message.delayedChannelCount
        response.muteUnreadCount = 0
        response.newBoxCount = 0
        MockInterceptionManager.shared.postMessage(command: .pushInboxCards, message: response)
    }
}

/// 1. Feed更新：name, time, lastMessage, avatar, badge, readStatus
/// 2. Feed删除
/// 3. Badge更新：unreadCount, filteredUnreadCount, filteredMuteUnreadCount
class PushCardPreviewMockFeedAPI: ChatCellMockFeedAPI {
    // 状态机
    enum State: Int {
        case updateFeed
        case removeFeed
        case updateBadge
        case end
    }

    // 依次Feed更新 -> Feed删除 -> Badge更新
    private let updateFeedCount = 5
    private let removeFeedCount = 5
    private let updateBadgeCount = 5
    private var currentCount = 0
    private var state: PushCardPreviewMockFeedAPI.State = .updateFeed

    override func putUserColdBootRequest() -> Observable<Void> {
        let ret = super.putUserColdBootRequest()
        currentCount = updateFeedCount
        state = .updateFeed

        let timer = Timer(timeInterval: 3, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            switch self.state {
            case .updateFeed: self.updateFeed()
            case .removeFeed: self.removeFeed()
            case .updateBadge: self.updateBadge()
            case .end: timer.invalidate()
            }
        }

        RunLoop.main.add(timer, forMode: .common)
        return ret
    }

    // name, time, lastMessage, avatar, badge, readStatus
    private func updateFeed() {
        guard currentCount > 0, state == .updateFeed else {
            currentCount = removeFeedCount
            state = .removeFeed
            return
        }

        // 为了方便观察，固定更新第一个
        var updateFeed = self.feedsGenerated.first!
        // name
        updateFeed.name = "New Name #\(updateFeedCount - currentCount)"
        // time
        updateFeed.displayTime = Int64(Date().timeIntervalSince1970)
        updateFeed.rankTime = updateFeed.displayTime
        updateFeed.updateTime = updateFeed.displayTime
        // lastMessage
        updateFeed.localizedDigestMessage = "New Msg #\(updateFeedCount - currentCount)"
        // TODO: avatar
//        updateFeed.avatarKey = ""
        // badge
        updateFeed.unreadCount = (0...100).randomElement() ?? 0
        // readStatus
        updateFeed.entityStatus = FeedCardPreview.EntityStatus.allCases.randomElement() ?? .read
        let message = FeedPreviewResponse(updatePreviews: [updateFeed])
        MockFeedPreviewPushGenerator.shared.post(message: message)

        currentCount -= 1
        if currentCount <= 0 {
            currentCount = removeFeedCount
            state = .removeFeed
        }
    }

    private func removeFeed() {
        guard currentCount > 0, state == .removeFeed else {
            currentCount = updateBadgeCount
            state = .updateBadge
            return
        }

        // 为了方便观察，每次删除第一个
        let removeFeed = feedsGenerated.removeFirst()
        let message = FeedPreviewResponse(removePreviews: [removeFeed])
        MockFeedPreviewPushGenerator.shared.post(message: message)

        currentCount -= 1
        if currentCount <= 0 {
            currentCount = updateBadgeCount
            state = .updateBadge
        }
    }

    private func updateBadge() {
        guard currentCount > 0, state == .updateBadge else {
            currentCount = 0
            state = .end
            return
        }

        let message = FeedPreviewResponse(unreadCount: (0...100).randomElement() ?? 0,
                                          filteredUnreadCount: (0...100).randomElement() ?? 0,
                                          filteredMuteUnreadCount: (0...100).randomElement() ?? 0,
                                          delayedChannelCount: (0...100).randomElement() ?? 0)
        MockFeedPreviewPushGenerator.shared.post(message: message)

        currentCount -= 1
        if currentCount <= 0 {
            currentCount = 0
            state = .end
        }
    }
}
