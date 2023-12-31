//
//  QueueManager.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/2/13.
//

import Foundation
import RxSwift
import LKCommonsLogging
import LarkCore

open class OutputTaskInfo<Type> {
    let task: () -> Void
    let duration: Double
    let type: Type
    init(task: @escaping () -> Void, duration: Double, type: Type) {
        self.task = task
        self.duration = duration
        self.type = type
    }

    func doTask() {
        self.task()
    }
}

public protocol OuputTaskTypeInfo {
    /// 任务是否可归并
    func canMerge(type: Self) -> Bool
    /// 任务执行时长
    func duration() -> Double
    /// barrier命名借鉴cpu barrier指令命名。cpu有动态调度换序指令的优化能力,但这种换序可能引入风险. 因此cpu 提供barrier指令，
    /// barrier指令防止cpu将barrier之前的指令交换到barrier之后，禁止“穿透”。套用到降频策略里，
    /// barrier任务防止barrier之前的任务被归并到barrier之后.
    func isBarrier() -> Bool
    /// 描述，可用于日志输出等场景
    var describ: String { get }
}

public extension OuputTaskTypeInfo {
    var describ: String {
        return "empty"
    }
}

/// 文档：https://bytedance.feishu.cn/space/doc/doccnfiS8tVm5de1TbEWAUatbfc
open class QueueManager<OuputTaskType: OuputTaskTypeInfo> {
    let logger = Logger.log(QueueManager.self, category: "lark.chat.QueueManager")

    public var dataQueueOperationCount: Int {
        return dataQueue.operationCount
    }

    public init() {}

    /// 恢复队列
    public func resumeQueue() {
        queueSuspendOperationCount.decrease(category: "QueueManager") { [weak self] in
            self?.doFirstTask()
            self?.dataQueue.isSuspended = false
        }
    }

    /// 暂停队列
    public func pauseQueue() {
        queueSuspendOperationCount.increase(category: "QueueManager") { [weak self] in
            self?.dataQueue.isSuspended = true
        }
    }

    /// 取消队列中的任务
    public func cancelAllTask() {
        self.dataQueue.cancelAllOperations()
        self.outputQueue.removeAll()
    }

    /// 当前队列是否处于暂停状态
    public func queueIsPause() -> Bool {
        return queueSuspendOperationCount.hasOperator
    }

    /// 通过闭包添加一个数据处理任务,可添加并行处理逻辑
    public func addDataProcess(_ process: @escaping () -> Void) {
        _ = Observable.just({
            process()
        })
        .observeOn(self.dataScheduler)
        .subscribe(onNext: { work in
            work()
        })
    }

    /// 通过Operation添加一个数据处理任务,Operation可设置优先级,可添加并行处理逻辑
    public func addDataProcessOperation(_ operation: Operation) {
        self.dataQueue.addOperation(operation)
    }

    /// 通过Operation添加一组数据处理任务,Operation可设置优先级,可添加并行处理逻辑
    public func addDataProcessOperations(_ operations: [Operation], waitUntilFinished: Bool = false) {
        self.dataQueue.addOperations(operations, waitUntilFinished: waitUntilFinished)
    }

    /// 添加并行子任务
    /// concurrentPerform 函数也与 sync 函数一样，会等待处理结束，因此推荐在 async 函数中异步执行 concurrentPerform 函数。
    /// concurrentPerform 函数可以实现高性能的循环迭代。
    public func concurrent(count: Int, perform: (Int) -> Void) {
        DispatchQueue.concurrentPerform(iterations: count) { (count) in
            perform(count)
        }
    }

    /// 添加一个输出任务,可指定该任务执行时间
    public func addOutput(type: OuputTaskType, task: @escaping () -> Void) {
        let duration = type.duration()
        if self.queueIsPause() {
            self.outputQueue.append(OutputTaskInfo(task: task, duration: duration, type: type))
        } else {
            if self.outputQueue.isEmpty {
                self.outputQueue.append(OutputTaskInfo(task: task, duration: duration, type: type))
                self.doFirstTask()
            } else {
                self.outputQueue.append(OutputTaskInfo(task: task, duration: duration, type: type))
            }
        }
    }

    /// 输出任务queue
    private var outputQueue: [OutputTaskInfo<OuputTaskType>] = []
    /// 数据处理queue
    private lazy var dataQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "QueueManagerDataQueue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
        return queue
    }()
    public lazy var dataScheduler: OperationQueueScheduler = {
        let scheduler = OperationQueueScheduler(operationQueue: dataQueue)
        return scheduler
    }()

    private var queueSuspendOperationCount = OperatorCounter(threadSafe: true)

}

private extension QueueManager {
    private func doFirstTask() {
        self.logger.info("Schedule trace doFirstTask \(self.outputQueue.count)")
        self.outputQueue = optimized(queue: self.outputQueue)
        if let taskInfo = self.outputQueue.first {
            taskInfo.doTask()
            self.doNextOutputTask(duration: taskInfo.duration)
        }
    }

    private func doNextOutputTask(duration: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            if !(self?.outputQueue.isEmpty ?? true) {
                _ = self?.outputQueue.removeFirst()
            }
            if !(self?.queueIsPause() ?? true) {
                self?.doFirstTask()
            }
        }
    }

    private func optimized(queue: [OutputTaskInfo<OuputTaskType>]) -> [OutputTaskInfo<OuputTaskType>] {
        var optimizedQueue: [OutputTaskInfo<OuputTaskType>] = []
        var tempSegmentQueue: [OutputTaskInfo<OuputTaskType>] = []
        for task in queue {
            if let index = tempSegmentQueue.firstIndex(where: { (optimizeTask) -> Bool in
                return optimizeTask.type.canMerge(type: task.type)
            }) {
                var barrierIndex: Int?
                for i in index..<tempSegmentQueue.count where tempSegmentQueue[i].type.isBarrier() {
                    barrierIndex = i
                }
                if let barrierIndex = barrierIndex {
                    optimizedQueue.append(contentsOf: tempSegmentQueue.prefix(barrierIndex + 1))
                    tempSegmentQueue.removeFirst(barrierIndex + 1)
                    tempSegmentQueue.append(task)
                } else {
                    tempSegmentQueue.remove(at: index)
                    tempSegmentQueue.append(task)
                }
            } else {
                tempSegmentQueue.append(task)
            }
        }
        optimizedQueue.append(contentsOf: tempSegmentQueue)
        if optimizedQueue.count > queue.count {
            //优化后的数组比优化前数量还大
            var describ: String = ""
            for task in queue {
                describ += task.type.describ + ", "
            }
            self.logger.error("Schedule trace optimizedQueue is wrong \(optimizedQueue.count) \(queue.count) \(describ)")
            print("Schedule trace optimizedQueue is wrong \(optimizedQueue.count) \(queue.count) \(describ)")
            assertionFailure("please give print log to zhaochen.09")
            //出现异常，直接返回输入的queue
            return queue
        }
        return optimizedQueue
    }
}
