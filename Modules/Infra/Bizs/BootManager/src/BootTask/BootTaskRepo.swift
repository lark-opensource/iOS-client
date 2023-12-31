//
//  BootTaskRepo.swift
//  BootManager
//
//  Created by sniperj on 2021/4/19.
//

import Foundation
import RunloopTools
import BootManagerConfig

/**
 Task容器，持有所有Task
 用于做Task重复过滤、延后

 不能直接被释放，切租户，应用级别的延迟任务，要继续执行
 */
internal final class BootTaskRepo {
    init() { }

    /// 这里持有全部Task
    var allTasks: [TaskIdentify: BootTask] = [:]
    var immediateTasks: [TaskIdentify: BootTask] = [:]

    /// 保证入队顺序
    var delayTasks: [BootTask] = []
    
    /// 取出当前需要执行的Task
    /// - Parameter identify: Task唯一标识
    @inline(__always)
    func dequeue(_ identify: TaskIdentify?) -> BootTask? {
        guard
            let taskID = identify,
            let task = immediateTasks[taskID] else { return nil }
        return task.state == TaskState.none ? task : nil
    }

    /// Task入库
    /// - Parameter identify: Task唯一标识
    @inline(__always)
    func enqueue(_ identify: TaskIdentify, launcher: Launcher, flow: BootFlow) {
        assert(Thread.isMainThread, "should occur on main thread!")
        guard
            !allTasks.keys.contains(identify),
            !NewBootManager.shared.globalTaskRepo.onceTasks.contains(identify),
            !NewBootManager.shared.globalTaskRepo.onceUserScopeTasks.contains(identify)
            else { return }
        guard let task = BootTaskRegistry.resolve(identify, context: launcher.context) else { return }
        task.launcher = launcher
        task.flow = flow
        allTasks[identify] = task

        /**
         首屏数据Preload
         如果与当前Tab不匹配，需要丢弃
         */
        if
            task.isFirstTabPreLoad,
            launcher.context.firstTab?.hasPrefix(task.firstTabURLString) != true {
            return
        }
        
        /*
         可懒加载，延后逻辑
            -可懒加载处理满足条件：满足isLazyTask方法注释的条件。
            -可延后任务满足条件
                - task指定scope，并且和首tap的scope不匹配
                - 快速登录
                - task所在的flow需要在指定延迟的flow之前
         */
        //判断当前flow和被延迟的flow是否符合逻辑顺序
        var canDelay: Bool = true
        if let delayType = task.delayType, let flowType = task.flow?.flowType {
            switch delayType {
            case .delayForIdle:
                if flowType == .cpuIdle {
                    canDelay = false
                }
            case .delayForFirstRender:
                if (flowType == .cpuIdle || flowType == .runloopIdle) {
                    canDelay = false
                }
            }
        }
        //可懒加载任务
        if NewBootManager.shared.isLazyTask(task: task) {
            NewBootManager.shared.lazyTasks.append(task)
        } else if //可延后执行任务
            !task.scope.isEmpty,
            launcher.context.scope.isDisjoint(with: task.scope),
            launcher.context.isFastLogin,
            canDelay {
            delayTasks.append(task)
        } else { //立即执行任务
            immediateTasks[identify] = task
        }

        // Deamon的任务，被持有，且释放上一次启动的
        if task.deamon {
            NewBootManager.shared.globalTaskRepo.deamonTasks[identify] = task
        }
    }

    /// 启动流程完成，清理Task
    func clearAll() {
        assert(Thread.isMainThread, "should occur on main thread!")
        self.allTasks = [:]
        self.delayTasks = []
        self.immediateTasks = [:]
        finish = true
    }
    var finish = false
}

internal final class BootGlobalTaskRepo {
    init() { }

    /// 生命周期只执行一次的Tasks
    internal var onceTasks: Set<TaskIdentify> = []

    internal var onceUserScopeTasks: Set<TaskIdentify> = []

    /**
     Task执行完默认会释放，
     如果需要持续监听事件，可以设置Task.deamon = true
     会被这个map持有，
     重新登录、切租户时，Task重新生成，释放之前的
     */
    var deamonTasks: [TaskIdentify: BootTask] = [:]

    /// 释放Deamon Task，业务可能需要重新生成
    /// - Parameter task: BootTask.identify
    func removeDeamonTask(_ identify: TaskIdentify) {
        DispatchQueue.main.mainAsyncIfNeeded {
            self.deamonTasks.removeValue(forKey: identify)
        }
    }
}
