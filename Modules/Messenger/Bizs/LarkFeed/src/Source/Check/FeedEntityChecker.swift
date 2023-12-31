//
//  FeedPreviewCheckerService.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/8/23.
//

import Foundation
import LarkModel

final class FeedPreviewCheckerService {
    static func checkIfInvalidFeed(_ feedId: String, _ FeedPreviewChecker: FeedPreviewChecker, _ currentUserId: String) -> Bool {
        guard FeedPreviewChecker.checkUser else { return false }
        let feedUserId = String(FeedPreviewChecker.userID)
        guard !currentUserId.isEmpty else {
            // 本地userId为空时，跳过检查，但会上报埋点
            FeedDataSyncTracker.trackFeedPreviewCheckError(feedId: feedId, currentUserId: currentUserId, feedUserId: feedUserId)
            return false
        }
        guard feedUserId != currentUserId else { return false }
        //上报埋点
        FeedDataSyncTracker.trackFeedPreviewCheckError(feedId: feedId, currentUserId: currentUserId, feedUserId: feedUserId)
        return true
    }
}
