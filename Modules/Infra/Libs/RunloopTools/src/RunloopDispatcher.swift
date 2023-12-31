//
//  RunloopDispatcher.swift
//  RunloopTools
//
//  Created by KT on 2019/9/18.
//

import Foundation
import ThreadSafeDataStructure
import LKCommonsLogging
import LarkPreload

public protocol RunloopDispatcherResponseable: AnyObject {
    // 有task，Runloop添加了Observer
    func didAddTriggerObserver()
    // task处理完成，Runloop移除Observer
    func didRemoveTriggerObserver()
}

public extension RunloopDispatcherResponseable {
    func didAddTriggerObserver() { }
    func didRemoveTriggerObserver() { }
}

/// 任务拆分到Runloop空闲时执行
public final class RunloopDispatcher {

    // MARK: - Public
    public internal(set) static var shared = RunloopDispatcher(trigger: RunloopTrigger())

    /// 整体开关，didFinishLaunching之后打开
    public static var enable = false
    
    /// 是否通过预加载框架调度任务
    public static var dispatchByPreload = false

    /// 添加任务，等Runloop空闲执行
    /// - Parameter priority: 优先级，默认medium
    /// - Parameter scope: 级别，默认user，登出不执行
    /// - Parameter taskAction: 任务
    /// - sequence 是否有顺序
    @discardableResult
    public func addTask(
        priority: Priority = .medium,
        scope: Scope = .user,
        identify: String? = nil,
        taskAction: @escaping Action,
        sequence: Bool = false
    ) -> Task {
        let task = Task(priority: priority,
                        scope: scope,
                        taskAction: taskAction,
                        identify: identify)
        if RunloopDispatcher.dispatchByPreload {
            if let removeTasks = PreloadMananger.shared.needRemoveRunloopTaskInLowDevice {
                for taskName in removeTasks {
                    if taskName == identify {
                        RunloopDispatcher.logger.info("remove Task with identify: \(task.identify)")
                        return task
                    }
                }
            }

            var preloadMoment: PreloadMoment = .runloopIdle
            if let delayTasks = PreloadMananger.shared.needDelayRunloopTaskInLowDevice {
                delayTasks.forEach { taskName in
                    if taskName == identify {
                        preloadMoment = .startOneMinute
                    }
                }
            }
            //桥接任务优先级
            var preloadPriority: LarkPreload.PreloadPriority = .middle
            switch priority {//原emergency桥接成.hight。原low桥接成.low
                case .emergency: preloadPriority = .hight
                case .low: preloadPriority = .low
                default: break
            }
            //兼容之前的场景，在runloopIdle的时候触发，并且之前的场景也有排序的逻辑，所以无需关系时序。
            PreloadMananger.shared.registerTask(preloadName: "runloopDispatcher_preload", preloadMoment: preloadMoment, biz: .unKnown, preloadType: .OtherType, hasFeedback: false, taskAction:{
                //兼容之前的场景，最终在主线程执行
                DispatchQueue.main.async {
                    taskAction()
                }
            }, stateCallBack: nil, scheduler: (sequence ? .async : .concurrent), priority: preloadPriority)
        } else {
            self.pool.addTask(task)
        }
        RunloopDispatcher.logger.info("Add Task with identify: \(task.identify)")
        return task
    }

    /// 清空User Scope的任务
    public func clearUserScopeTask() {
        self.pool.clear(scope: .user)
    }

    /// 外界设置拦截项
    /// - Parameter checker: 譬如CPUy闲时判断
    public func addCommitChecker(_ checker: DispatcherChecker) {
        self.checker.append(checker)
    }

    public func addObserver(_ observer: RunloopDispatcherResponseable) {
        self.observers.append(observer)
    }

    // MARK: - Private
    private static let logger = Logger.log(RunloopDispatcher.self)
    private let pool = Pool()
    private let checker = Checker()
    private let trigger: Triggerable
    private var observers: SafeArray<RunloopDispatcherResponseable> = [] + .readWriteLock

    init(trigger: Triggerable) {
        self.trigger = trigger
        self.trigger.reciver = self
        self.pool.reciver = self
    }
}

extension RunloopDispatcher: TriggerResponseable {
    public func didAddObserver() {
        self.observers.forEach { $0.didAddTriggerObserver() }
    }

    public func didRemoveObserver() {
        self.observers.forEach { $0.didRemoveTriggerObserver() }
    }

    public func willTrigger() -> Bool {
        guard RunloopDispatcher.enable else { return false }

        // 执行任务 (第一个非Check 或者 第一个Check且pass)
        let first = self.pool.sortedTask.first { [weak self] in
            guard let self = self else { return false }
            return !$0.needCheck || self.checker.pass($0)
        }

        guard let task = first else { return false }
        task.exec()

        // 删除第一个执行的任务
        self.pool.deleteFinished()
        return true
    }
}

extension RunloopDispatcher: PoolResponseable {
    func afterAddTask() {
        self.trigger.setup()
    }

    func afterDeleteTask() {
        // 最后一个任务移除Observer
        guard self.pool.isEmpty else { return }
        self.trigger.clean()
    }
}
