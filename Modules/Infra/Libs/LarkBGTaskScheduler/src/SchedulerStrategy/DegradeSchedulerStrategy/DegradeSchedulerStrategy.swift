//
//  DegradeSchedulerStrategy.swift
//  LarkBGTaskScheduler
//
//  Created by 李勇 on 2020/2/10.
//

import UIKit
import Foundation
import ThreadSafeDataStructure

/// iOS13以下任务调度策略
final class DegradeSchedulerStrategy: SchedulerStrategy {
    /// 日志工具
    var logger: LKBGLogger?
    /// 日志工具
    var tracker: LKBGTracker?
    /// 所有的任务provider
    private var taskProviders: SafeDictionary<String, (TaskProvider, RefreshTask?)> = [:] + .readWriteLock
    /// 所有任务将会在此OperationQueue中执行
    private let operationQueue = OperationQueue()

    init() {
        self.operationQueue.name = "degrade_strategy_refresh_operation_queue"
        self.operationQueue.qualityOfService = .background
    }

    // MARK: - SchedulerStrategy
    /// 开关控制任务执行
    var enable: Bool = false {
        didSet {
            // 如果enable为fasle，则设置为neverBGFetch也就永远不会执行，否则设置为至少隔30分钟执行一次
            let type = self.enable ? 30 * 60 : UIApplication.backgroundFetchIntervalNever
            // setMinimumBackgroundFetchInterval必须在主线程
            DispatchQueue.main.async {
                UIApplication.shared.setMinimumBackgroundFetchInterval(type)
            }
            self.logger?.info("degrade-refresh：enable is \(self.enable)")
        }
    }

    func register(type: TaskType, identifier: String, task: @escaping TaskProvider) -> RegisterError {
        guard type == .refresh else { return .notSupport }
        self.taskProviders[identifier] = (task, nil)
        self.logger?.info("degrade-refresh：register \(identifier), tasks.count = \(self.taskProviders.count)")
        return .none
    }

    func cancel(type: TaskType, identifier: String) {
        guard type == .refresh else { return }
        self.taskProviders.removeValue(forKey: identifier)
        self.logger?.info("degrade-refresh：cancel \(identifier), tasks.count = \(self.taskProviders.count)")
    }

    /// 应用将要启动完成
    func applicationDidLaunching() {
        self.logger?.info("degrade-refresh：application did launching")
        // 设置为never，默认永久不执行
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
    }

    /// 应用被后台唤起执行任务
    func applicationPerformFetch(completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        self.logger?.info("degrade-refresh：application perform fetch handle")
        // 准备Tasks
        self.readyTasks()

        // 先copy一份数据，在此方法执行期间保持数据的一致性
        let tasks = self.taskProviders.map({ ($0, $1.1) }).filter({ $1 != nil }) as? [(String, RefreshTask)] ?? []
        // 没有任务，或之前的任务没执行完则不进行此轮执行
        guard !tasks.isEmpty, self.operationQueue.operations.isEmpty else {
            self.logger?.info("degrade-refresh：skip handle, tasks.count = \(tasks.count)")
            self.tracker?.refresh(metric: ["cost": "0", "finish": true, "strategy": "degrade"], category: ["empty": "true"])
            completionHandler(.newData)
            return
        }

        // 统计总共耗时
        let allBeginDate = NSDate().timeIntervalSince1970
        func allCost() -> String {
            return String(format: "%.2f", NSDate().timeIntervalSince1970 - allBeginDate)
        }

        self.logger?.info("degrade-refresh：handle begin execute \(tasks.count) tasks")
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
                    self.logger?.info("degrade-refresh：handle end, \(executeInfoStr) allCost：\(allCost())")
                    self.tracker?.refresh(metric: ["cost": allCost(), "finish": true, "strategy": "degrade"], category: ["empty": "false"])
                    completionHandler(.newData)
                }
            }

            executeInfoStr += "\(taskIdentifier) begin,"
            self.operationQueue.addOperation(operation)
        }
    }

    /// 应用将要进入后台
    func applicationDidEnterBackground() {
        self.logger?.info("degrade-refresh：application enter background")
    }

    /// 应用将要进入前台，停止所有任务执行
    func applicationWillEnterForeground() {
        self.logger?.info("degrade-refresh：application enter foreground")
        self.operationQueue.cancelAllOperations()
    }

    // MARK: - private
    /// 准备Tasks，从TaskProvider创建Task
    private func readyTasks() {
        let tempTaskProviders = self.taskProviders.getImmutableCopy()
        tempTaskProviders.forEach { (key, value) in
            // 如果有存的值，则不需要再创建
            if value.1 != nil { return }
            guard let task = value.0() as? RefreshTask else { return }

            self.taskProviders[key] = (value.0, task)
        }
    }
}
