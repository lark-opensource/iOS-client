//
//  BaseFeedsViewModel+DataQueue.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/8/24.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import LarkSDKInterface
import RustPB
import UniverseDesignToast
import ThreadSafeDataStructure
import RunloopTools
import LKCommonsLogging
import LarkPerf
import LarkModel
import AppReciableSDK

enum FeedDataQueueTaskType: String {
    // 目前仅作为log使用，记录queue的操作日志
    case draging, // 手指触摸/离开屏幕
         menuShow, // ipad上的长按cell出popView
         atGuide, // 启动时的at引导
         muteGuide, // 启动时的mute引导
         cellEdit, // cell 左右滑动时，挂起queue
         switchFilterTab, // 切filter时，强制resume queue
         setOffset, // setContent造成的滚动，区别于手势滑动
         scrollToRow, // scrollToRow造成的滚动，区别于手势滑动
         popoverForTeam // [团队]的moreAction
}

// MARK: - Queue
extension BaseFeedsViewModel {
    func setupQueue() {
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
        logQueue.maxConcurrentOperationCount = 1
        logQueue.qualityOfService = .userInteractive
    }

    /// 为队列操作加锁或解锁，注意加锁解锁操作必须成对出现
    func changeQueueState(_ isSuspended: Bool, taskType: FeedDataQueueTaskType) {
        FeedContext.log.info("feedlog/dataStream/queue. \(self.listBaseLog), taskType: \(taskType.rawValue), oldState: \(queue.isSuspended), isSuspended: \(isSuspended)")
        queue.isSuspended = isSuspended
    }

    /// 向queue里提交一个task，串行执行
    func commit(_ task: @escaping () -> Void) {
        queue.addOperation(task)
    }

    /// 获取Queue状态
    func isQueueSuspended() -> Bool {
        queue.isSuspended
    }
}
