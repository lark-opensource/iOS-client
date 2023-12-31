//
//  FeedDataQueue.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/8/18.
//

import Foundation

final class FeedDataQueue {
    enum QueueType: String {
        case filterData,
             labelData
    }

    let queue = OperationQueue()
    let queueType: QueueType

    init(_ queueType: QueueType) {
        self.queueType = queueType
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
    }

    static func executeOnMainThread(_ task: @escaping (() -> Void)) {
        if Thread.isMainThread {
            task()
        } else {
            DispatchQueue.main.async {
                task()
            }
        }
    }

    func executeOnChildThread(_ task: @escaping () -> Void) {
        queue.addOperation(task)
    }

    func frozenDataQueue(_ taskType: String) {
        FeedContext.log.info("feedlog/dataqueue for:\(queueType), frozen old: \(isQueueState()), taskType: \(taskType)")
        queue.isSuspended = true
    }

    func resumeDataQueue(_ taskType: String) {
        FeedContext.log.info("feedlog/dataqueue for:\(queueType), resume old: \(isQueueState()), taskType: \(taskType)")
        queue.isSuspended = false
    }

    func isQueueState() -> Bool {
        queue.isSuspended
    }
}
