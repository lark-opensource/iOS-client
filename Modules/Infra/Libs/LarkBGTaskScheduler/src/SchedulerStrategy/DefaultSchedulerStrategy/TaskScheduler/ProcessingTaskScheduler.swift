//
//  ProcessingTaskScheduler.swift
//  LarkBGTaskScheduler
//
//  Created by 李勇 on 2020/2/10.
//

import Foundation
import Dispatch
import BackgroundTasks
import ThreadSafeDataStructure

/// iOS13及以上处理任务调度
@available(iOS 13.0, *)
final class ProcessingTaskScheduler: TaskScheduler {
    /// 处理任务标示
    private static let taskIdentifier = "processing_id"
    /// 是否调用过BGTaskScheduler.shared.register
    private var registered: SafeAtomic<Bool> = false + .readWriteLock
    /// 日志工具
    var logger: LKBGLogger?
    /// 打点工具
    var tracker: LKBGTracker?
    /// 支持处理的最大任务数
    private static let maxSupportTaskCount = 1
    /// 所有的任务
    private var taskProviders: SafeDictionary<String, (TaskProvider, ProcessingTask?)> = [:] + .readWriteLock
    /// 所有任务将会在此OperationQueue中执行
    private let operationQueue = OperationQueue()

    init() {
        self.operationQueue.name = "default_strategy_processing_operation_queue"
        self.operationQueue.qualityOfService = .background
    }

    // MARK: - TaskScheduler
    /// 开关控制任务执行
    var enable: Bool = false {
        didSet {
            self.logger?.info("default-processing：enable is \(self.enable)")
            // enable为false需要cancel之前register的task，因为上次进入后台可能register过；
            // enable为true不需要进行任何操作，因为设置enable只可能是在前台，当再次进入后台时会submit。
            if !self.enable {
                // fix：cancel卡顿问题
                DispatchQueue.global().async {
                    BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: ProcessingTaskScheduler.taskIdentifier)
                }
            }
        }
    }

    /// 添加处理任务，执行时所有任务将会并发执行，identifier相同会覆盖，任务将会有300s左右的执行时间
    func register(identifier: String, task: @escaping TaskProvider) -> RegisterError {
        guard self.taskProviders.count < ProcessingTaskScheduler.maxSupportTaskCount else { return .tooManyTask }
        self.taskProviders[identifier] = (task, nil)
        self.logger?.info("default-processing：register \(identifier), tasks.count = \(self.taskProviders.count)")
        return .none
    }

    /// 取消处理任务
    func cancel(identifier: String) {
        self.taskProviders.removeValue(forKey: identifier)
        self.logger?.info("default-processing：cancel \(identifier), tasks.count = \(self.taskProviders.count)")
    }

    /// 应用启动时需要注册任务
    func applicationDidLaunching() {
        self.logger?.info("default-processing：application did launching")
        // 队列传串行队列，让执行内容和超时回调能够顺序执行
        let processingQueue = DispatchQueue(label: "processing_task_register_queue", qos: .background)
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: ProcessingTaskScheduler.taskIdentifier,
            using: processingQueue) { (task) in
                guard let task = task as? BGProcessingTask else { return }
                self.handle(task: task)
            }
        self.registered.value = true
    }

    /// 应用退出后台需要提交任务
    func applicationDidEnterBackground() {
        self.logger?.info("default-processing：application enter background")
        // 准备Tasks
        self.readyTasks()
        self.submit()
    }

    /// 应用将要进入前台，停止所有任务
    func applicationWillEnterForeground() {
        self.logger?.info("default-processing：application enter foreground")
        self.operationQueue.cancelAllOperations()
    }

    // MARK: - private
    /// 准备Tasks，从TaskProvider创建Task
    private func readyTasks() {
        let tempTaskProviders = self.taskProviders.getImmutableCopy()
        tempTaskProviders.forEach { (key, value) in
            // 如果有存的值，则不需要再创建
            if value.1 != nil { return }
            guard let task = value.0() as? ProcessingTask else { return }

            self.taskProviders[key] = (value.0, task)
        }
    }

    /// 提交任务
    private func submit() {
        // 如果enable为fasle，则不进行submit，BGTask也就永远不会执行。
        // registered必须为true，否则submit时会crash
        guard self.enable, self.registered.value else {
            self.logger?.info("default-processing：skip task submit, enable is false")
            return
        }

        // 先copy一份数据，在此方法执行期间保持数据的一致性
        let tasks = self.taskProviders.values.compactMap({ $1 })

        let request = BGProcessingTaskRequest(identifier: ProcessingTaskScheduler.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)
        request.requiresNetworkConnectivity = tasks.contains(where: { $0.requiresNetworkConnectivity })
        request.requiresExternalPower = tasks.contains(where: { $0.requiresExternalPower })
        // 主线程submit可能会造成卡死
        DispatchQueue.global().async {
            do {
                try BGTaskScheduler.shared.submit(request)
                self.logger?.info("default-processing：task submit succcess")
            } catch {
                self.logger?.info("default-processing：task submit error：\(error)")
            }
        }
    }

    /// 处理任务
    private func handle(task: BGProcessingTask) {
        self.logger?.info("default-processing：application processing task handle")
        // 准备Tasks
        self.readyTasks()
        // 再次提交，可继续获取执行的机会
        self.submit()

        // 先copy一份数据，在此方法执行期间保持数据的一致性
        let tasks = self.taskProviders.map({ ($0, $1.1) }).filter({ $1 != nil }) as? [(String, ProcessingTask)] ?? []
        // 没有任务，或之前的任务没执行完则不进行此轮执行
        guard !tasks.isEmpty, self.operationQueue.operations.isEmpty else {
            self.logger?.info("default-processing：skip handle, tasks.count = \(tasks.count)")
            self.tracker?.processing(metric: ["cost": "0", "finish": true, "strategy": "default"], category: ["empty": "true"])
            task.setTaskCompleted(success: true)
            return
        }

        // 统计总共耗时
        let allBeginDate = NSDate().timeIntervalSince1970
        func allCost() -> String {
            return String(format: "%.2f", NSDate().timeIntervalSince1970 - allBeginDate)
        }

        self.logger?.info("default-processing：handle begin execute \(tasks.count) tasks")
        // 累加执行时的内容，结束时聚合打印
        var executeInfoStr = ""

        // 开始提交任务
        var finishTaskCount: Int32 = 0; let allTaskCount = tasks.count
        tasks.forEach {
            // 当前执行任务的标示
            let taskIdentifier = $0
            let operation = TaskOperation(task: $1)

            // 统计子任务耗时
            let beginDate = NSDate().timeIntervalSince1970
            func cost() -> String {
                return String(format: "%.2f", NSDate().timeIntervalSince1970 - beginDate)
            }

            // Operation执行完、执行中被cancel、未得到执行就被cancel都会调用completionBlock
            operation.completionBlock = {
                executeInfoStr += "\(taskIdentifier) cost \(cost()),"
                // 检测是否所有方法都执行完
                if OSAtomicAdd32(1, &finishTaskCount) == allTaskCount {
                    self.logger?.info("default-processing：handle end, \(executeInfoStr) allCost：\(allCost())")
                    self.tracker?.processing(metric: ["cost": allCost(), "finish": true, "strategy": "default"], category: ["empty": "false"])
                    task.setTaskCompleted(success: true)
                }
            }

            executeInfoStr += "\(taskIdentifier) begin,"
            self.operationQueue.addOperation(operation)
        }

        // 设置任务超时回调
        task.expirationHandler = {
            self.logger?.info("default-processing：handle expiration, \(executeInfoStr) allCost：\(allCost())")
            self.tracker?.processing(metric: ["cost": allCost(), "finish": false, "strategy": "default"], category: ["empty": "false"])
            self.operationQueue.cancelAllOperations()
            task.setTaskCompleted(success: false)
        }
    }
}
