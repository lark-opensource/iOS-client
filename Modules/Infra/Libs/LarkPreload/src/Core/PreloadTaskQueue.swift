//
//  PreloadTaskQueue.swift
//  Lark
//
//  Created by huanglx on 2023/1/17.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//

import Foundation
import ThreadSafeDataStructure
import LKCommonsLogging

/// Queue状态
enum QueueState: String {
    case unStart /// 未开始
    case run     /// 开始
    case pause   /// 暂停
    case cancel  /// 取消
    case end     /// 结束
}

///监听代理
protocol PreloadTaskQueueDelegate: AnyObject {
    //队列派发完成
    func finishQueue(priority: PreloadPriority)
    //队列暂停派发
    func pauseQueue(priority: PreloadPriority)
    //是否可调度
    func canSchedule(priority: PreloadPriority) -> Bool
    //开始监控
    func startMonitor()
}

/// 预处理队列
class PreloadTaskQueue {
    ///待执行的task
    private var tasks: SafeArray<PreloadTask> = [] + .readWriteLock
    /// 队列优先级，存放不同优先级的task，默认是middle
    var priority: PreloadPriority = .middle
    ///回调代理
    weak var reciever: PreloadTaskQueueDelegate?
    
    private static var logger = Logger.log(PreloadTaskQueue.self)
    
    ///通过队列状态处理逻辑
    var state: QueueState = .unStart {
        didSet {
            guard oldValue != state else { return }
            switch state {
                case .unStart: do {
                }
                case .run: do {
                    self.executeQueue()
                }
                case .end: do {
                    self.finishQueue()
                }
                case .pause: do {
                    self.pauseQueue()
                }
                case .cancel: do {
                    self.cancelQueue()
                }
            }
        }
    }
    
    init(priority: PreloadPriority) {
        self.priority = priority
    }
    
    //MARK: 任务调度
    /// 开始执行
    func executeQueue() {
        self.doFirstOrLastTask()
    }
    
    ///调度第一个任务或者最后一个任务，没有任务代表队列执行完成
    private func doFirstOrLastTask() {
        var currentTask = self.tasks.first
        //是否允许后进先出
        if PreloadSettingsManager.enableLIFO() {
            currentTask = self.tasks.last
        }
        if let task = currentTask {
            //判断任务是否可执行,过滤主动调度，被框架取消等情况
            guard self.checkTaskCanExecute(task: task) else {
                self.doNextTask()
                return
            }
            //如果满足执行条件执行后面的任务
            if self.reciever?.canSchedule(priority: self.priority) ?? true {
                //user生命周期执行一次
                if task.runOnlyOnceInUserScope {
                    PreloadMananger.shared.onceUserScopeTasks.insert(task.preloadName)
                }
                //整个app生命周期执行一次
                if task.runOnlyOnce {
                    PreloadMananger.shared.onceTasks.insert(task.preloadName)
                }
                PreloadMananger.shared.taskScheduler.scheduler(task)
                self.doNextTask()
                return
            } else {//如果不满足条件暂停当前的队列，开启监控
                self.state = .pause
                self.reciever?.startMonitor()
            }
        } else { //没有可执行任务，代表执行结束
            self.state = .end
        }
    }
    
    ///判断任务是否可以执行
    private func checkTaskCanExecute(task: PreloadTask) -> Bool {
        //APP生命周期/user生命周期只执行一次的情况
        let isOnceTask: Bool = (PreloadMananger.shared.onceTasks.contains(task.preloadName) || PreloadMananger.shared.onceUserScopeTasks.contains(task.preloadName))
        //本地命中率过低，低端机制定不进行预加载的,被取消的，已经执行完的，不会进行预加载
        if isOnceTask || task.isCancelByLowDevice || task.isCancelByHit || task.state == .cancel || task.state == .end {
            PreloadTracker.trackSkipTask(taskId: task.identify)
            //只有一次执行的
            if isOnceTask {
                task.state = .cancel
            }
            //低端机被禁用，可以通过兜底方案主动
            if task.isCancelByLowDevice {
                task.state = .disableByLowDevice
            }
            //命中率低被禁用的可以通过兜底方案主动触发。 
            if task.isCancelByHit {
                task.state = .disableByHitRate
            }
            return false
        }
        return true
    }
    
    //在任务限频周期内派发的个数
    var dispatchCount: Int = 0
    
    ///执行下一个任务
    private func doNextTask() {
        if !(self.tasks.isEmpty) {
            if PreloadSettingsManager.enableLIFO() {
                self.tasks.remove(at: self.tasks.count - 1)
            } else {
                _ = self.tasks.remove(at: 0)
            }
        }
        guard self.state == .run else { return }
        
        //如果打散时间间隔超过0，并且任务等待个数超过n个就会被限频，每调度n/2个就会限频一次
        if self.tasks.count > PreloadSettingsManager.taskBreakUpPendingCount(), PreloadSettingsManager.taskBreakUpPendingCount() > 0 { //达到限频条件
            if dispatchCount >= PreloadSettingsManager.taskBreakUpPendingCount() / 2 { //触发限频
                PreloadTaskQueue.logger.info("preload_taskBreakUp")
                DispatchQueue.main.asyncAfter(deadline: .now() + PreloadSettingsManager.getTaskDuration()) { [weak self] in
                    self?.dispatchCount = 0
                    if self?.state == .run {
                        self?.doFirstOrLastTask()
                    }

                }
            } else {
                self.dispatchCount += 1
                self.doFirstOrLastTask()
            }
        } else {
            self.dispatchCount = 0
            self.doFirstOrLastTask()
        }
    }
    
    //MARK: 任务添加，暂停，取消等逻辑
    ///添加任务
    func addTask(task: PreloadTask) {
        self.tasks.append(task)
    }
    
    ///获取任务个数
    func getTaskCount() -> Int {
        return self.tasks.count
    }
    
    ///执行完Queue
    private func finishQueue() {
        self.reciever?.finishQueue(priority: self.priority)
    }
    
    ///暂停Queue
    private func pauseQueue() {
        self.reciever?.pauseQueue(priority: self.priority)
    }
    
    ///取消Queue
    private func cancelQueue() {
        PreloadTaskQueue.logger.info("preload_cancelQueue_priprity:\(self.priority)")
    }
}
