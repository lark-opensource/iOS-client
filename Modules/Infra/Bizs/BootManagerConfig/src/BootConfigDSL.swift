//
//  BootConfigDSL.swift
//  BootManager
//
//  Created by sniperj on 2021/4/19.
//

import Foundation

@resultBuilder struct RawBuilder {
    static func buildBlock<T>(_ tasks: T...) -> [T] {
        tasks
    }
}

typealias TaskBuilder = RawBuilder
typealias FlowBuilder = RawBuilder

public struct FlowConfig {
    /// 流程名
    public let name: FlowType
    /// 一个流程中包含的任务List
    public var tasks: [TaskConfig]?
    /// 一个流程中包含的其他流程
    public var flows: [FlowConfig]?
    init(_ name: FlowType) {
        self.name = name
    }

    func tasks(@TaskBuilder _ builder: () -> [TaskConfig]) -> Self {
        var flowConfig = self
        flowConfig.tasks = builder()
        return flowConfig
    }

    func flows(@FlowBuilder _ builder: () -> [FlowConfig]) -> Self {
        var flowConfig = self
        flowConfig.flows = builder()
        return flowConfig
    }
}

public struct TaskConfig {
    /// task名称
    public let name: String
    /// 当前Task能够跳转的task
    public var checkout: [FlowConfig]?

    init(_ name: String) {
        self.name = name
    }
    func canCheckout(@FlowBuilder _ builder: () -> [FlowConfig]) -> Self {
        var taskConfig = self
        taskConfig.checkout = builder()
        return taskConfig
    }
}
