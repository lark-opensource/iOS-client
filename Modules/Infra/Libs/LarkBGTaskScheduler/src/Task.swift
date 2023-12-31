//
//  Task.swift
//  LarkBGTaskScheduler
//
//  Created by 李勇 on 2020/2/10.
//

import Foundation

/// 完成回调
public typealias Completed = () -> Void
/// 任务provider，在真正需要执行任务时才会创建Task
public typealias TaskProvider = () -> Task

/// 任务类型
public enum TaskType {
    /// 刷新任务，对应RefreshTask
    case refresh
    /// 处理任务，对应ProcessingTask
    case processing
}

/// 任务，不应直接继承此类，应继承RefreshTask/ProcessingTask，所有任务在进入前台时会取消执行；
/// 会保证相同identifier的任务串行执行，不会存在两个相同identifier的任务同时执行的情况；
public protocol Task {
    /// 任务标示，用于覆盖/取消之前注册的任务
    static var identifier: String { get }
    /// 通知任务可以开始执行，该方法在子线程被调用，completed用于告诉调用方已经执行完毕
    func execute(completed: @escaping Completed)
    /// 该任务将要取消执行，可能有以下几种情况：
    /// 1：执行超时；
    /// 2：App进入前台。
    /// 建议Task收到此回调时停止执行内部操作，以免费电。
    func cancel()
}

/// 刷新任务
public protocol RefreshTask: Task {}

/// 处理任务，只在iOS13以上才会得到执行
public protocol ProcessingTask: Task {
    /// 是否需要网络连接
    var requiresNetworkConnectivity: Bool { get }
    /// 是否需要外接电源
    var requiresExternalPower: Bool { get }
}
