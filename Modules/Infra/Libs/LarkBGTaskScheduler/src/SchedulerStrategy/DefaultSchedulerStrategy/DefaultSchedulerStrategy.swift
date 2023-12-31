//
//  DefaultSchedulerStrategy.swift
//  LarkBGTaskScheduler
//
//  Created by 李勇 on 2020/2/10.
//

import UIKit
import Foundation
import ThreadSafeDataStructure

/// iOS13及以上调度策略
@available(iOS 13, *)
final class DefaultSchedulerStrategy: SchedulerStrategy {
    /// 日志工具
    var logger: LKBGLogger? {
        didSet { self.refresh.logger = self.logger; self.processing.logger = self.logger }
    }
    /// 打点工具
    var tracker: LKBGTracker? {
        didSet { self.refresh.tracker = self.tracker; self.processing.tracker = self.tracker }
    }
    /// 所有提供的任务调度器
    private let refresh = RefreshTaskScheduler()
    private let processing = ProcessingTaskScheduler()
    private lazy var schedulers: [TaskType: TaskScheduler] = [.refresh: self.refresh, .processing: self.processing]

    // MARK: - SchedulerStrategy
    /// 开关控制任务执行
    var enable: Bool = false {
        didSet { self.refresh.enable = self.enable; self.processing.enable = self.enable }
    }

    /// 注册任务
    func register(type: TaskType, identifier: String, task: @escaping TaskProvider) -> RegisterError {
        guard let scheduler = self.schedulers[type] else { return .other }
        return scheduler.register(identifier: identifier, task: task)
    }

    /// 取消任务
    func cancel(type: TaskType, identifier: String) {
        self.schedulers[type]?.cancel(identifier: identifier)
    }

    /// 应用将要启动完成
    func applicationDidLaunching() {
        self.schedulers.forEach({ $0.1.applicationDidLaunching() })
    }

    /// 应用被后台唤起执行任务
    func applicationPerformFetch(completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        completionHandler(.newData)
    }

    /// 应用将要进入后台
    func applicationDidEnterBackground() {
        self.schedulers.forEach({ $0.1.applicationDidEnterBackground() })
    }

    /// 应用将要进入前台
    func applicationWillEnterForeground() {
        self.schedulers.forEach({ $0.1.applicationWillEnterForeground() })
    }
}
