//
//  SchedulerStrategy.swift
//  LarkBGTaskScheduler
//
//  Created by 李勇 on 2020/2/10.
//

import UIKit
import Foundation

/// 调度器策略
protocol SchedulerStrategy {
    /// 开关控制任务执行
    var enable: Bool { get set }
    /// 任务相关
    func register(type: TaskType, identifier: String, task: @escaping TaskProvider) -> RegisterError
    func cancel(type: TaskType, identifier: String)
    /// 应用生命周期
    func applicationDidLaunching()
    func applicationPerformFetch(completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    func applicationDidEnterBackground()
    func applicationWillEnterForeground()
    /// 日志工具
    var logger: LKBGLogger? { get set }
    /// 打点工具
    var tracker: LKBGTracker? { get set }
}
