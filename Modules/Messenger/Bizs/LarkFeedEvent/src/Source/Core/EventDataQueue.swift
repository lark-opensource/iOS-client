//
//  DataQueue.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2022/9/27.
//

import Foundation

final class EventDataQueue {

    enum TaskType: String {
        case draging
    }

    private let dataQueue: OperationQueue

    init() {
        self.dataQueue = OperationQueue()
        dataQueue.maxConcurrentOperationCount = 1
        dataQueue.qualityOfService = .userInteractive
    }

    func frozenDataQueue(_ taskType: EventDataQueue.TaskType) {
        EventManager.log.info("eventlog/queue frozen old: \(isQueueState()), taskType: \(taskType)")
        dataQueue.isSuspended = true
    }

    func resumeDataQueue(_ taskType: EventDataQueue.TaskType) {
        EventManager.log.info("eventlog/queue resume old: \(isQueueState()), taskType: \(taskType)")
        dataQueue.isSuspended = false
    }

    func isQueueState() -> Bool {
        dataQueue.isSuspended
    }

    func addTask(_ task: @escaping () -> Void) {
        let t = {
            task()
        }
        dataQueue.addOperation(t)
    }
}
