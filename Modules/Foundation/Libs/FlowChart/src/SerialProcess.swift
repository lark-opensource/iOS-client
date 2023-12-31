//
//  SerialProcess.swift
//
//  Created by JackZhao on 2022/1/23.
//

/// 串型process
/// 1. 输入输出类型相同的process
/// 2. 可组装task/process
/// 
import Foundation
final public class FlowChartSerialProcess<I: FlowChartInput, C: FlowChartContext>: FlowChartProcess<I, I, C> {
    override public var identify: String { "FlowChartSerialProcess" }
    private let contextIdKey = "contextId"

    /// 待执行的[task]/[process]
    private var tasks: [FlowChartTask<I, I, C>] = []
    private var processes: [FlowChartProcess<I, I, C>] = []

    private func randomString() -> String {
        let letters = "0123456789"
        return String((0 ..< 10).map { _ in (letters.randomElement() ?? "x") })
    }

    public init(_ tasks: [FlowChartTask<I, I, C>] = [],
                context: C) {
        self.tasks = tasks
        super.init(context: context)
    }

    public init(_ task: FlowChartTask<I, I, C>,
                context: C) {
        self.tasks = [task]
        super.init(context: context)
    }

    public init(context: C,
                _ tasksCallback: () -> [FlowChartTask<I, I, C>]) {
        self.tasks = tasksCallback()
        super.init(context: context)
    }

    public init(_ processes: [FlowChartProcess<I, I, C>] = [],
                context: C) {
        self.processes = processes
        super.init(context: context)
    }

    public func append(_ task: FlowChartTask<I, I, C>) {
        // 如果processes有值，则不能添加task
        guard self.processes.isEmpty else {
            assertionFailure("error input")
            return
        }
        self.tasks.append(task)
    }

    public func append(_ process: FlowChartProcess<I, I, C>) {
        // 如果tasks有值，则不能添加process
        guard self.tasks.isEmpty else {
            assertionFailure("error input")
            return
        }
        self.processes.append(process)
    }

    public override func run(input: I, _ resConsumer: @escaping ResponseConsumer = { _ in }) {
        var input = input
        if input.extraInfo[self.contextIdKey] == nil {
            input.extraInfo[self.contextIdKey] = self.randomString()
        }

        // 得到待执行的[task]/[process]
        var units: [FlowChartUnit<I, I, C>] = self.tasks.isEmpty ? self.processes : self.tasks
        guard !units.isEmpty else {
            assertionFailure("empty input")
            return
        }

        // 1. 执行resConsumer回调，对外抛出执行结果，目前用于日志
        // 2. 解析上一task/process执行结果，判断继续/终止执行
        @discardableResult
        func processRes<I: FlowChartInput>(_ value: FlowChartValue<I>, resConsumer: ResponseConsumer?, identify: String) -> I? {
            switch value {
            case .success(let model):
                resConsumer?(.success(identify, extraInfo: model.extraInfo))
                return model
            case .error(let error):
                resConsumer?(.failure(identify, error: error))
                self.accept(.error(error))
                return nil
            }
        }

        // 串联所有的task/process
        let first = units.removeFirst()
        var preview = first
        while !units.isEmpty {
            let next = units.removeFirst()
            if let process = preview as? FlowChartProcess, let nextProcess = next as? FlowChartProcess {
                process.next(nextProcess, resConsumer: resConsumer) { res in
                    processRes(res, resConsumer: resConsumer, identify: process.identify)
                }
            } else if let task = preview as? FlowChartTask, let nextTask = next as? FlowChartTask {
                task.next(nextTask) { res in
                    processRes(res, resConsumer: resConsumer, identify: task.identify)
                }
            } else {
                assertionFailure("unknown type")
            }
            preview = next
        }
        // 指定最后一个task/process的执行完成回调
        preview.onEnd { [weak self] res in
            processRes(res, resConsumer: resConsumer, identify: preview.identify)
            // 最有一个task/process的执行结果，作为本process的执行结果
            // 如果是err，processRes中已经执行过一次self.accept(.error(error))
            self?.accept(res)
        }

        // 开始执行第一个task/process
        if let first = first as? FlowChartProcess {
            first.run(input: input, resConsumer)
        } else if let first = first as? FlowChartTask {
            first.run(input: input)
        }
    }
}
