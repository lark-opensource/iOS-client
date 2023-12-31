//
//  CustomBootTask.swift
//  BootManager
//
//  Created by huanglx on 2023/12/7.
//

import Foundation
import RunloopTools
import LarkPreload

final class RunloopAndCpuIdleTask: FlowBootTask, Identifiable {
    static var identify = "RunloopAndCpuIdleTask"

    override var runOnlyOnceInUserScope: Bool { return false }

    override func execute(_ context: BootContext) {
        RunloopDispatcher.enable = true
        //不通过预加载触发添加监听。
        if !NewBootManager.shared.dispatchByPreload() {
            let checker = DispatcherCPUChecker()
            RunloopDispatcher.shared.addCommitChecker(checker)
            RunloopDispatcher.shared.addObserver(checker)
        }
        
        //添加runloopIdle任务
        RunloopDispatcher.shared.addTask(
            priority: .required,
            scope: .user,
            identify: "runloopIdle") { [weak launcher] in
                if let launcher = launcher {
                    NewBootManager.shared.trigger(with: .runloopIdle, launcher: launcher)
                }
            }
        
        //添加cpuIdle任务
        RunloopDispatcher.shared.addTask(
            priority: .required,
            scope: .user,
            identify: "cpuIdle") { [weak launcher] in
                if let launcher = launcher {
                    NewBootManager.shared.trigger(with: .cpuIdle, launcher: launcher)
                }
            }.waitCPUFree()
    }
}

/**
 1 .首屏Tab对应的数据预加载
 2. 非首屏情况下会被丢弃
 业务要在ViewDidLoad里面拉数据
 */
open class FirstTabPreloadBootTask: FlowBootTask {
    open override var scheduler: Scheduler { return .concurrent }

    override var isFirstTabPreLoad: Bool { return true }
}
