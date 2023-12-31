//
//  BootFlow.swift
//  BootManager
//
//  Created by sniperj on 2021/4/19.
//

import UIKit
import Foundation
import BootManagerConfig
import RunloopTools
import LarkPreload
import LKCommonsTracker

/// Flow状态
public enum FlowState: String {
    /// 初始化
    case none
    /// 开始
    case start
    /// 暂停（分支、异步）
    case pause
    /// 结束
    case end
    /// 等待外界触发（此状态备用）
    case awaitTrigger
}

/// 启动流程
internal final class BootFlow {

    /// 对应流程的Task配置
    let config: FlowConfig

    /// 属于哪一个流程
    let flowType: FlowType

    /// 启动器
    weak var launcher: Launcher?

    /// 开始执行的task
    private var startAtTask: TaskIdentify?

    /// task集合
    lazy var configTasks: [TaskConfig] = {
        var tasks: [TaskConfig] = []
        guard let flowTasks = config.tasks else { return tasks }
        guard let startAtTask = startAtTask else {
            tasks.append(contentsOf: flowTasks)
            return tasks
        }
        var index = 0
        for task in flowTasks {
            if startAtTask == task.name {
                break
            }
            index += 1
        }
        tasks.append(contentsOf: flowTasks.suffix(from: index))
        return tasks
    }()

    //桥接启动节点
    func bridgeBootKeyNode(flowType: FlowType) -> BootKeyNode {
        var bridgeValue: BootKeyNode = .unKnown
        switch flowType {
            case .beforeLoginFlow: do {
                bridgeValue = .beforeLoginNode
                break
            }
            case .afterLoginFlow: do {
                bridgeValue = .afterLoginNode
                break
            }
            default: break
        }
        return bridgeValue
    }

    var state: FlowState = .none {
        didSet {
            guard oldValue != state else { return }

            switch state {
            case .start: do {
                //监听flow开始
                BootMonitor.shared.doBootKeyNode(keyNode: self.bridgeBootKeyNode(flowType: self.flowType))
                if UIApplication.shared.applicationState == .background,
                   self.flowType == .afterLoginFlow {
                    RunloopDispatcher.enable = true
                    RunloopDispatcher.shared.addTask(priority: .emergency) {
                        self.executeFlow()
                    }
                } else {
                    self.executeFlow()
                }
            }
            case .end: do {
                //监听flow结束，统计flow耗时。
                BootMonitor.shared.doBootKeyNode(keyNode: self.bridgeBootKeyNode(flowType: self.flowType), isEnd: true)
                if oldValue == .pause {
                    // FIXME: 有可能这里回调时，launcher已经插入新的flow了.., 后面的任务被提前运行..
                    // 比如firstRender任务先执行, 然后继续执行下去..
                    self.launcher?.excute()
                }
            }
            case .awaitTrigger, .none, .pause: break
            }
        }
    }

    /// Task管理仓
    internal var taskRepo: BootTaskRepo? {
        return self.launcher?.taskRepo
    }
    /// 初始化分支
    /// - Parameter path: BootTaskConfig里面初始化的Stage切换路径
    init(with flowConfig: FlowConfig, launcher: Launcher) {
        self.config = flowConfig
        self.flowType = flowConfig.name
        self.launcher = launcher
    }

    /// 从flow的task任务开始执行
    /// - Parameter taskIdentify: task Identiry
    func startAtTask(taskIdentify: TaskIdentify) {
        startAtTask = taskIdentify
    }

    /// 获取需要延迟执行的任务 适用于afterRender/idle
    /// - Returns: tasks
    func getDelayTask() -> [BootTask]? {
        guard let taskRepo = self.taskRepo else {
            return nil
        }
        var tasks: [BootTask] = []
        if flowType == .cpuIdle {
            tasks = taskRepo.delayTasks.filter { (task) -> Bool in
                task.delayType == .delayForIdle
            }
        }
        if flowType == .runloopIdle {
            tasks = taskRepo.delayTasks.filter { (task) -> Bool in
                task.delayType == .delayForFirstRender
            }
        }
        return tasks
    }

    /// 执行完状态会变为end
    /// 如果有任务没有执行完, 会暂停并返回pause状态..
    func executeFlow() {
        func runAndShouldBreakLoop(_ task: BootTask) -> Bool {
            task.flow = self
            task.run()
            // 任务没有执行完，可能是Branch、或者异步
            if task.state != .end {
                NewBootManager.logger.info("boot_breakLoop_\(String(describing: task.identify))_\(String(describing: task.flow?.flowType))")
                return true
            }
            return false
        }
        guard let launcher = self.launcher else { return }
        let taskRepo = launcher.taskRepo
        assert(Thread.isMainThread, "should occur on main thread!")
        assert(!launcher.disposed)
        assert(!taskRepo.finish, "结束后不应该还有任务运行")

        #if DEBUG || ALPHA
        if config.name == .afterLoginFlow {
            precondition(launcher.context.currentUserID != nil, "should already set userID after login")
        }
        #endif
        printVerbose("[Info] \(config.name) flow start")
        if let delayTask = getDelayTask() {
            for task in delayTask {
                guard task.state == TaskState.none else { continue }
                if runAndShouldBreakLoop(task) {
                    /// FIXME: delayTask没有被消耗，且没有通过执行过滤，
                    /// 如果有异步任务, 可能会重复运行
                    self.state = .pause
                    return
                }
            }
        }
        for taskConfig in self.configTasks {
            // enqueue会过滤是否重复执行, 另外也会判断是否放入delayTask中
            taskRepo.enqueue(taskConfig.name, launcher: launcher, flow: self)
            // 获取对应的immediateTasks，但虽然叫dequeue，其实并不会消耗，是一个只读属性
            guard let task = taskRepo.dequeue(taskConfig.name) else { continue }
            // run会标记运行过，然后上面的enqueue会做过滤, 重进这个flow时就不会重复运行
            if runAndShouldBreakLoop(task) {
                self.state = .pause
                return
            }
        }
        self.state = .end
    }
}
