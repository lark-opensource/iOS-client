//
//  TaskScheduler.swift
//  LarkBGTaskScheduler
//
//  Created by 李勇 on 2020/2/10.
//

import Foundation

/// 任务调度器
protocol TaskScheduler {
    /// 开关控制任务执行
    var enable: Bool { get set }
    /// 任务相关
    func register(identifier: String, task: @escaping TaskProvider) -> RegisterError
    func cancel(identifier: String)
    /// 应用生命周期
    func applicationDidLaunching()
    func applicationDidEnterBackground()
    func applicationWillEnterForeground()
    /// 日志工具
    var logger: LKBGLogger? { get set }
    /// 打点工具
    var tracker: LKBGTracker? { get set }
}
