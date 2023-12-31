//
//  TaskOperation.swift
//  LarkBGTaskScheduler
//
//  Created by 李勇 on 2020/2/12.
//

import Foundation

/// 由Task驱动的TaskOperation，支持在执行过程中被cancel
public final class TaskOperation: Operation {
    private let task: Task

    public init(task: Task) {
        self.task = task
    }

    /// 在Task未完成执行时卡住此方法，此方法结束后OperationQueue中将移除该Operation
    /// 如果该Operation未得到执行就被cancel了，则不会执行到main方法
    override public func main() {
        let semaphore = DispatchSemaphore(value: 0)
        // 监听当前Operation被取消
        DispatchQueue.global().async {
            // 如果task已经执行完，则不再检测cancel态
            while !self.isFinished {
                sleep(UInt32(0.5))
                // 如果未被外部取消，则继续检测cancel态
                guard self.isCancelled else { continue }

                // 告知任务将要取消执行，并终止main方法
                self.task.cancel()
                semaphore.signal()
                break
            }
        }
        // 监听任务执行结束
        self.task.execute { semaphore.signal() }
        semaphore.wait()
    }
}
