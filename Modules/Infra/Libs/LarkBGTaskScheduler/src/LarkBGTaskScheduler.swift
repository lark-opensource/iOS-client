//
//  LarkBGTaskScheduler.swift
//  LarkBGTaskScheduler
//
//  Created by 李勇 on 2020/2/10.
//

import UIKit
import Foundation

/// Lark后台任务调度
public final class LarkBGTaskScheduler {
    /// 单例
    public static let shared = LarkBGTaskScheduler()
    /// 日志工具
    public var logger: LKBGLogger? {
        didSet { self.strategy.logger = self.logger }
    }
    /// 打点工具
    public var tracker: LKBGTracker? {
        didSet { self.strategy.tracker = self.tracker }
    }
    /// 调度器策略
    private var strategy: SchedulerStrategy

    init() {
        if #available(iOS 13, *) {
            self.strategy = DefaultSchedulerStrategy()
        } else {
            self.strategy = DegradeSchedulerStrategy()
        }
    }

    // MARK: - 总开关
    /// 开关控制任务执行
    public var enable: Bool = false {
        didSet { self.strategy.enable = self.enable }
    }

    // MARK: - 任务相关
    /// 注册任务
    @discardableResult
    public func register(type: TaskType, identifier: String, task: @escaping TaskProvider) -> RegisterError {
        return self.strategy.register(type: type, identifier: identifier, task: task)
    }

    /// 取消任务
    public func cancel(type: TaskType, identifier: String) {
        self.strategy.cancel(type: type, identifier: identifier)
    }

    // MARK: - 应用生命周期
    /// 应用将要启动完成
    public func applicationDidLaunching() {
        self.strategy.applicationDidLaunching()
    }

    /// 应用被后台唤起执行任务
    public func applicationPerformFetch(completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        self.strategy.applicationPerformFetch(completionHandler: completionHandler)
    }

    /// 应用将要进入后台
    public func applicationDidEnterBackground() {
        self.strategy.applicationDidEnterBackground()
    }

    /// 应用将要进入前台
    public func applicationWillEnterForeground() {
        self.strategy.applicationWillEnterForeground()
    }
}
