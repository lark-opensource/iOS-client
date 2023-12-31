//
//  Launcher.swift
//  BootManager
//
//  Created by sniperj on 2021/4/19.
//

import Foundation
import RunloopTools
import BootManagerConfig

/// 启动器，用于负责启动任务的执行调度
/// 仅应该被单例持有，不应该被使用方持有，**特别主要不要在主线程外异步持有导致生命周期延长**
/// NOTE: 目前BootManager内部的对象和方法，都应该在主线程运行, 由此保证没有并发，状态切换的一致性..
internal final class Launcher {
    /// 启动上下文
    let context: BootContext
    /// launch的taskRepo持有task
    let taskRepo = BootTaskRepo()
    /// 当前启动中所有的启动流程
    var flowArray: [BootFlow] = []
    /// 当前执行的flow
    var curFlow: FlowType?
    var disposed = false
    // MARK: - Public
    init(context: BootContext) {
        self.context = context
    }
    /// 冷启动默认执行的流程
    func defaultExecute() {
        executeFlow(with: .didFinishLaunchFlow)
    }

    /// 执行某一个流程，如果有taskIdentiry的话，会到对应的流程中，startAt TaskIdentiry
    /// - Parameters:
    ///   - flowType: 需要执行的flow
    ///   - task: 开始执行的task
    func executeFlow(with flowType: FlowType, task: TaskIdentify? = nil) {
        assert(Thread.current.isMainThread, "must call in main Thread")
        guard let flowConfig = flowMap[flowType] else {
            assertionFailure("flow 必须在BootConfig.swift中注册")
            return
        }
        var tempFlowArray: [BootFlow] = []
        let curFlow = BootFlow(with: flowConfig,
                               launcher: self)
        tempFlowArray.append(curFlow)
        if let taskIdentify = task {
            curFlow.startAtTask(taskIdentify: taskIdentify)
        }
        if let flows = flowConfig.flows {
            for config in flows {
                let flow = BootFlow(with: config,
                                    launcher: self)
                tempFlowArray.append(flow)
            }
        }
        /// 核心运行逻辑
        /// Launcher被manager持有，切换时释放..
        /// 只往前面插入，不清理。
        /// 执行完了flow会标记为end, 从而被过滤.
        /// 如果task中断，会暂停执行直到再次触发execute
        /// 再次触发也会遍历所有的task，但是运行过的不会再运行（task生命周期只能run一次）

        /// 如果是checkout，会插入新的flow（先运行），然后继续运行旧的flow.
        /// flow中的task实例存在taskRepo里，靠运行后的state排重，一次创建只能运行一次
        /// 另外还有登录流程可能重新触发boot, launcher被替换重置..
        /// FIXME: 可能会通过重复的executeFlow来恢复当前flow的运行。会被重复插入flowArray, 虽然Task运行会排重
        /// FIXME: checkout没有检查，可以任意切换..
        flowArray.insert(contentsOf: tempFlowArray, at: 0)
        excute()
    }

    /// execute Flow
    func excute() {
        for flow in flowArray where flow.state != .end {
            curFlow = flow.flowType
            // 如果执行过程中有checkout，会插入到前面。运行到这里时，还处于start状态，没有变化，直接返回
            // 之前的flow execute调用栈返回，变成pause状态，也退出..
            // 但是如果pause状态后再被excute到，会再次运行(task只运行一次，会继续后面的task..)
            flow.state = .start
            if flow.state != .end {
                return
            }
        }
    }

    /// 外界触发的flow runloopIdle && idle
    /// - Parameter flow: flow type
    func trigger(with flow: FlowType) {
        executeFlow(with: flow)
    }

    func dispose() {
        self.disposed = true
    }
}
