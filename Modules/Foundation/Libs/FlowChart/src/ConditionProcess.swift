//
//  ConditionProcess.swift
//
//  Created by JackZhao on 2022/1/17.
//

/// Process: process的派生类, 用来组装两个不同的task或者process(输入相同)
/// 1. 结果异步返回
/// 2. 无状态, 且明确暴露结果态: success or error
///
import Foundation
final public class FlowChartConditionProcess<I: FlowChartInput, O: FlowChartOutput, C: FlowChartContext>: FlowChartProcess<I, O, C> {
    override public var identify: String { "FlowChartConditionProcess" }
    /// 运行时决定要执行的task/process
    private let switchHandler: (I) -> (FlowChartUnit<I, O, C>, I)?

    public init(context: C,
                _ switchHandler: @escaping (I) -> (FlowChartUnit<I, O, C>, I)?) {
        self.switchHandler = switchHandler
        super.init(context: context)
    }

    public override func run(input: I, _ resConsumer: @escaping ResponseConsumer) {
        // 通过判断得到的下一个要执行的task/process
        guard let result = switchHandler(input) else { return }

        // 执行resConsumer回调，对外抛出执行结果，目前用于日志
        func processRes<I: FlowChartInput>(_ value: FlowChartValue<I>, resConsumer: ResponseConsumer?, identify: String) {
            switch value {
            case .success(let model):
                resConsumer?(.success(identify, extraInfo: model.extraInfo))
            case .error(let error):
                resConsumer?(.failure(identify, error: error))
            }
        }

        let unit = result.0
        // 指定task/process的执行完成回调
        unit.onEnd { [weak self] output in
            processRes(output, resConsumer: resConsumer, identify: unit.identify)
            // task/process的执行结果，作为本process的执行结果
            self?.accept(output)
        }
        // 开始执行task/process
        if let process = unit as? FlowChartProcess {
            process.run(input: result.1, resConsumer)
        } else if let task = unit as? FlowChartTask {
            task.run(input: result.1)
        }
    }
}
