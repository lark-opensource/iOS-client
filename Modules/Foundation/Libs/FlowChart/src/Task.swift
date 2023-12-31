//
//  Task.swift
//
//  Created by JackZhao on 2022/1/4.
//  Copyright © 2022 JACK. All rights reserved.
//

/// Task: 单一流程的最小化运行任务
/// 1. 单一逻辑,不应该判断下一个task
/// 2. 结果异步返回
/// 3. 无状态, 且明确暴露结果态: success or Error
/// 4. 不能直接使用，需要继承实现自己的逻辑
/// 5. 需要包含在Process中运行
///
import Foundation
open class FlowChartTask<I: FlowChartInput, O: FlowChartOutput, C: FlowChartContext>: FlowChartUnit<I, O, C> {
    /// 指定本task执行完后下一个要执行的task
    /// - Parameters:
    ///   - task: 下一个要执行的task
    ///   - transform: 把本task的output转为下一个要执行的task的input
    /// - Returns: 下一个要执行的task，用于链式调用：taskA.next(taskB).next(...)
    @discardableResult
    public func next<NI, NO, NC: FlowChartContext>(_ task: FlowChartTask<NI, NO, NC>,
                                                   transform: @escaping (FlowChartValue<O>) -> NI?) -> FlowChartTask<NI, NO, NC> {
        self.onEnd { output in
            if let res = transform(output) {
                task.run(input: res)
            }
        }
        return task
    }

    /// 开始执行本task，子类必须复写
    /// - Parameter input: 执行需要的输入
    open func run(input: I) {
        fcAbstractMethod()
    }
}
