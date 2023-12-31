//
//  LabelMainListDataQueue.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/20.
//

import Foundation

/** LabelMainListDataQueue的设计：队列的纯粹操作
1. 增加queue日志
2. 丰富queue函数
*/

final class LabelMainListDataQueue {

    enum TaskType: String {
        case draging,
             showSettingSheet,
             willActive,
             cellEdit,
             menuShow
    }

    private let dataQueue: OperationQueue

    init() {
        self.dataQueue = OperationQueue()
        dataQueue.maxConcurrentOperationCount = 1
        dataQueue.qualityOfService = .userInteractive
    }

    func frozenDataQueue(_ taskType: LabelMainListDataQueue.TaskType) {
        FeedContext.log.info("feedlog/label/queue frozen old: \(isQueueState()), taskType: \(taskType)")
        dataQueue.isSuspended = true
    }

    func resumeDataQueue(_ taskType: LabelMainListDataQueue.TaskType) {
        FeedContext.log.info("feedlog/label/queue resume old: \(isQueueState()), taskType: \(taskType)")
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
