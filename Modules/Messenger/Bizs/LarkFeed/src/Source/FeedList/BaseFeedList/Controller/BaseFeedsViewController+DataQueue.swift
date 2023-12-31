//
//  BaseFeedsViewController+DataQueue.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/4.
//

import Foundation

// MARK: - 滑动时，禁止刷新UI
extension BaseFeedsViewController {
    func onlyFullReloadWhenScrolling(_ isScrolling: Bool, taskType: FeedDataQueueTaskType) {
        guard isScrolling != self.isScrolling else { return }
        FeedContext.log.info("feedlog/onlyFullReloadWhenScrolling taskType: \(taskType.rawValue), oldScrolling: \(self.isScrolling), isScrolling: \(isScrolling)")
        self.isScrolling = isScrolling
    }
}
