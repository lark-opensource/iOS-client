//
//  BootTaskScheduler.swift
//  BootManager
//
//  Created by sniperj on 2021/4/19.
//

import UIKit
import Foundation
import LarkPreload

internal final class BootTaskScheduler {
    /// 并行队列
    lazy var concurrentQueue: OperationQueue = {
        let op = OperationQueue()
        op.qualityOfService = .userInteractive
        let coreCount = ProcessInfo.processInfo.activeProcessorCount
        op.maxConcurrentOperationCount = min(coreCount, 4)
        return op
    }()

    /// 串行队列
    lazy var serialQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "Lark.BootManager.serialQueue", qos: .utility)
        return queue
    }()

    /// 在对应线程执行
    /// - Parameter task: LaunchTask
    func scheduler(_ task: BootTask) {
        assert(Thread.isMainThread, "should occur on main thread!")
        guard let launcher = task.launcher, !launcher.disposed,
            case let context = launcher.context
        else {
            assertionFailure("task 找不到当前启动 context")
            return
        }
        //任务交给预加载框架调度
        guard !schedulerByPreloadEnable(task: task) else {
            NewBootManager.logger.info("boot_schedulerByPreload_\(String(describing: task.identify))")
            self.schedulerByPreload(task: task, context: context)
            return
        }
        //兜底预加载框架没生效时指定触发时机-目前仅兼容启动一分钟的场景，后期会把预加载框架全放开，不需要做兜底
        if task.triggerMonent == .startOneMinute {
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                self.schedulerByType(task: task, context: context)
            }
        } else {
            self.schedulerByType(task: task, context: context)
        }
    }
    
    //调度任务
    func schedulerByType(task: BootTask, context: BootContext){
        switch task.scheduler {
        case .main:
            DispatchQueue.main.mainAsyncIfNeeded {
                let time = CACurrentMediaTime()
                task.execute(context)
                NewBootManager.shared.bootTaskCostData[task.identify] = (CACurrentMediaTime() - time) * 1_000
            }
        case .async:
            self.serialQueue.async { task.execute(context) }
        case .concurrent:
            self.concurrentQueue.addOperation { task.execute(context) }
        }
    }
    
    //MARK: 通过预加载框架调度
    //是否通过预加载调度。
    private func schedulerByPreloadEnable(task: BootTask) -> Bool {
        //非阻塞任务，非可切换分支任务，并且没有被禁用。
        if task.forbiddenPreload {
            return false
        }
        //快速登录
        let isFastLogin = task.launcher?.context.isFastLogin ?? false
        //预加载框架是否可用
        let preloadEnable = NewBootManager.shared.dispatchByPreload()
        //是否异步任务
        let isAsyncTask = task.scheduler == .async || task.scheduler == .concurrent
        //是否闲时任务
        let isIdleTask = task.flow?.flowType == .cpuIdle || task.flow?.flowType == .runloopIdle
        //预加载能力开启，fastlogin，并且是异步任务或者闲时任务，采用预加载框架调度
        if isFastLogin, preloadEnable, (isAsyncTask || isIdleTask) {
            return true
        }
       return false
    }
    
    ///通过预加载框架调度异步任务
    private func schedulerByPreload(task: BootTask, context: BootContext) {
        //桥接队列的执行线程,如果是在主线程执行的，需要在子线程串行调度，执行的时候再切到主线程
        var scheduler: LarkPreload.Scheduler
        switch task.scheduler {
        case .main, .async:
            scheduler = .async //原来主线程执行的需要在子线程串行调度，执行时回到主线程
        case .concurrent:
            scheduler = .concurrent
        }
        
        //确定任务的优先级，首tab任务的优先级最高。
        var priority: LarkPreload.PreloadPriority = .middle
        if !task.scope.isEmpty,
        !(task.launcher?.context.scope.isDisjoint(with: task.scope) ?? true) {
            priority = .hight
        }
        
        //确定任务的触发时机-如果不是none默认是runloopIdle。
        var preloadMoment = task.triggerMonent == .none ? .runloopIdle : task.triggerMonent

        if let removeTasks = PreloadMananger.shared.needRemoveTaskInLowDevice {
            for identify in removeTasks {
                if identify == task.identify {
                    return
                }
            }
        }

        if let delayTasks = PreloadMananger.shared.needDelayTaskInLowDevice {
            delayTasks.forEach { identify in
                if identify == task.identify {
                    preloadMoment = .startOneMinute
                }
            }
        }

        
        //避免预加载的启动任务被释放，需要强持有。
        NewBootManager.shared.preloadTasks.append(task)
        
        //把任务注册给预加载框架
        PreloadMananger.shared.registerTask(preloadName: task.identify ?? "", preloadMoment: preloadMoment, biz: .ClodStart, preloadType: .BootTaskType, hasFeedback: task.hasFeedback, taskAction: {
            if task.scheduler == .main {
                DispatchQueue.main.async { //回到主线程执行
                    task.execute(context)
                    //预加载启动任务执行完毕释放任务。
                    NewBootManager.shared.removePreloadTask(task: task)
                }
            } else {
                task.execute(context)
                //预加载启动任务执行完毕释放任务。
                NewBootManager.shared.removePreloadTask(task: task)
            }
        }, stateCallBack: { _ in
        }, taskIdCallBack: { preloadId in
            //设置预加载id和闲时任务id映射。
            PreloadMananger.shared.setPreloadIdKVs(preloadIdKey: task.identify, preloadIdValue: preloadId)
        }, scheduler: scheduler, priority: priority)
    }
}
