//
//  MarkDoneMockFeedAPI.swift
//  LarkMessengerDemoMockFeeds
//
//  Created by 袁平 on 2020/5/25.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkModel
import LarkFeed
import RustPB
import LarkRustClient
import RxSwift

/// Move To Done 过程中，收到Feed更新
class MarkDoneWhenUpdateMockFeedAPI: ChatCellMockFeedAPI {
    private let maxCount = 30
    private var currentCount = 0

    // 模拟Feed更新
    override func putUserColdBootRequest() -> Observable<Void> {
        let ret = super.putUserColdBootRequest()
        currentCount = maxCount

        let timer = Timer(timeInterval: 2, repeats: true) { [weak self] timer in
            guard let self = self, self.currentCount > 0 else {
                timer.invalidate()
                return
            }
            self.currentCount -= 1
            // 为了方便观察，每次都取第一个Feed进行更新
            var feed = self.feedsGenerated.first!
            feed.name = "New Name #\(self.maxCount - self.currentCount)"
            feed.localizedDigestMessage = "New Msg #\(self.maxCount - self.currentCount)"
            feed.displayTime = Int64(Date().timeIntervalSince1970)
            feed.rankTime = feed.displayTime
            feed.updateTime = feed.displayTime
            let message = FeedPreviewResponse(updatePreviews: [feed])

            MockFeedPreviewPushGenerator.shared.post(message: message)
        }

        RunLoop.main.add(timer, forMode: .common)
        return ret
    }

    override func moveToDone(feedId: String, entityType: FeedCard.EntityType) -> Observable<Void> {
        return super.moveToDone(feedId: feedId, entityType: entityType)
    }
}

/// Move To Done 过程中，删除Feed
class MarkDoneWhenRemoveMockFeedAPI: ChatCellMockFeedAPI {
        private let maxCount = 30
        private var currentCount = 0

        // 模拟Feed更新
        override func putUserColdBootRequest() -> Observable<Void> {
            let ret = super.putUserColdBootRequest()
            currentCount = maxCount

            let timer = Timer(timeInterval: 2, repeats: true) { [weak self] timer in
                guard let self = self, self.currentCount > 0 else {
                    timer.invalidate()
                    return
                }
                self.currentCount -= 1
                // 为了方便观察，每次都取第一个Feed进行删除
                let removeFeed = self.feedsGenerated.removeFirst()
                let message = FeedPreviewResponse(removePreviews: [removeFeed])

                MockFeedPreviewPushGenerator.shared.post(message: message)
            }

            RunLoop.main.add(timer, forMode: .common)
            return ret
        }
}
