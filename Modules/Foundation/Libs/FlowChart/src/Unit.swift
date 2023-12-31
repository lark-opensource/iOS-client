//
//  Unit.swift
//
//  Created by JackZhao on 2022/1/30.
//

/// process和task的抽象类
/// 1. 业务方不能使用，无需感知
/// 2. 存放process和task共有的属性、方法
///
import Foundation
open class FlowChartUnit<I: FlowChartInput, O: FlowChartOutput, C: FlowChartContext> {
    /// process/task的唯一标识，目前用于日志输出
    open var identify: String {
        assertionFailure()
        return ""
    }
    /// 执行本process/task所需的最小依赖
    public weak var flowContext: C?
    /// 本process/task执行完后，触发的block回调
    private var lock = pthread_rwlock_t()
    private lazy var outputCallback: (FlowChartValue<O>) -> Void = { _ in }

    public init(context: C) {
        self.flowContext = context
        pthread_rwlock_init(&lock, nil)
    }

    /// 通知本process/task执行完毕，内部只是执行了outputCallback回调
    /// - Parameter value: 执行的输出
    public func accept(_ value: FlowChartValue<O>) {
        defer { pthread_rwlock_unlock(&self.lock) }
        pthread_rwlock_rdlock(&self.lock)
        self.outputCallback(value)
    }

    /// 指定本process/task执行完后触发的block回调
    /// - Parameter process: 执行完后触发的block回调
    public func onEnd(_ process: @escaping (FlowChartValue<O>) -> Void) {
        pthread_rwlock_wrlock(&self.lock)
        defer { pthread_rwlock_unlock(&self.lock) }
        self.outputCallback = process
    }
}
