//
//  Process.swift
//
//  Created by JackZhao on 2022/1/4.
//  Copyright © 2022 JACK. All rights reserved.
//

import Foundation
public typealias ResponseConsumer = (FlowChartResponse) -> Void

/// Process: task的载体, 某一个流程的抽象
/// 1. 组装task的执行逻辑, 将复杂的分支抽象为多个线性的独立过程
/// 2. 具有切换Process的能力
/// 3. 结果异步返回
/// 4. 无状态, 且明确暴露结果态: success or error
/// 5. 不能直接使用，需要继承实现自己的逻辑，比如：FlowChartSerialProcess、FlowChartConditionProcess
///
open class FlowChartProcess<I: FlowChartInput, O: FlowChartOutput, C: FlowChartContext>: FlowChartUnit<I, O, C> {
    /// 指定本task执行完后下一个要执行的process，用于支持多Process串行执行
    /// - Parameters:
    ///   - task: 下一个要执行的process
    ///   - resConsumer: 执行时实时对外抛出执行状态，目前用于日志，最外层process的执行结果不会抛出
    ///   - transform: 把本process的output转为下一个要执行的process的input
    /// - Returns: 下一个要执行的process，用于链式调用：processA.next(processB).next(...)
    @discardableResult
    public func next<NI, NO, NC: FlowChartContext>(_ process: FlowChartProcess<NI, NO, NC>,
                                                   resConsumer: @escaping ResponseConsumer = { _ in },
                                                   transform: @escaping ((_ output: FlowChartValue<O>) -> NI?)) -> FlowChartProcess<NI, NO, NC> {
        self.onEnd { output in
            if let res = transform(output) {
                process.run(input: res, resConsumer)
            }
        }
        return process
    }

    /// 开始执行本process，子类必须复写
    /// - Parameters:
    ///   - input: 执行需要的输入
    ///   - resConsumer: 用于实时对外抛出执行状态，目前用于日志
    open func run(input: I, _ resConsumer: @escaping ResponseConsumer = { _ in }) {
        fcAbstractMethod()
    }
}
