//
//  PreloadTaskQueuePool.swift
//  LarkPreload
//
//  Created by huanglx on 2023/3/15.
//

import Foundation
import LKCommonsLogging
import ThreadSafeDataStructure

class PreloadTaskQueuePool {
    
    private static var logger = Logger.log(PreloadTaskQueuePool.self)
    
    //队列池
    var queuePool: SafeDictionary<PreloadPriority, PreloadTaskQueue> = [:] + .readWriteLock
    // 注册任务队列
    private var registerTaskArray: SafeArray<PreloadTask> = [] + .readWriteLock
    ///原始task
    private var originalTasks: SafeArray<PreloadTask> = [] + .readWriteLock
    //预加载时机监听器
    private var momentTriggers: SafeArray<MomentTriggerDelegate> = [] + .readWriteLock
    
    // 任务调度队列
    lazy var addTaskQueue: DispatchQueue = {
        return DispatchQueue(label: "Lark.PreloadTaskQueuePool.addTaskQueue", qos: .utility)
    }()
    
    // 触发器
    lazy var dispatcher: PreloadDispatcher = {
        var dispatcher = PreloadDispatcher()
        dispatcher.reciever = self
        return dispatcher
    }()
    
    ///创建一个队列
    private func createQueueByPripority(priority: PreloadPriority) -> PreloadTaskQueue {
        let taskQueue = PreloadTaskQueue(priority: priority)
        taskQueue.reciever = self
        return taskQueue
    }

    //MARK: 任务入队逻辑
    ///任务入队
    func enqueueByPriority(task: PreloadTask, priority: PreloadPriority) -> PreloadTaskQueue {
        var currentQueue: PreloadTaskQueue
        //根据不同的优先级放入到不同的队列
        if let queue = self.queuePool[priority] {
            currentQueue = queue
        } else {
            currentQueue = self.createQueueByPripority(priority: priority)
            self.queuePool[priority] = currentQueue
        }
        currentQueue.addTask(task: task)
        return currentQueue
    }
    
    //通过优先级进行排序-从高->低
    private var sortedQueue: [PreloadTaskQueue] {
        let sortedQueues = self.queuePool.sorted { ($0.0).rawValue > ($1.0).rawValue }
        return sortedQueues.map { $0.1 }
    }
    
    ///是否有比当前队列更低优先级任务
    private func hasLowerTask(currentQueue: PreloadTaskQueue) -> Bool {
        var hasLowerTask: Bool = false
        //过滤低优先级队列
        let lowerQueue = self.sortedQueue.filter { taskQueue in
            taskQueue.priority.rawValue < currentQueue.priority.rawValue
        }
        //判断低优先级队列是否有任务
        lowerQueue.forEach { taskQueue in
            if taskQueue.getTaskCount() > 0 {
                hasLowerTask = true
            }
        }
        return hasLowerTask
    }
    
    ///是否有比当前优先级更高优先级任务
    private func hasHigherTask(currentQueue: PreloadTaskQueue) -> Bool {
        var hasHigherTask: Bool = false
        //过滤高优先级队列
        let higherQueue = self.sortedQueue.filter { taskQueue in
            taskQueue.priority.rawValue > currentQueue.priority.rawValue
        }
        //判断高优先级队列是否有任务
        higherQueue.forEach { taskQueue in
            if taskQueue.getTaskCount() > 0 {
                hasHigherTask = true
            }
        }
        return hasHigherTask
    }
    
    ///暂停正在执行的调度
    private func paushDispatchIng() {
        self.queuePool.values.forEach { taskQueue in
            if taskQueue.state == .run {
                taskQueue.state = .pause
            }
        }
        self.dispatcher.isDispatchIng = false
    }
    
    //动态调整任务优先级，根据task的优先级放入到不同的队列中。
    func enqueueByPriority(task: PreloadTask) {
        task.state = .await
        self.originalTasks.append(task)
        self.addTaskQueue.async {
            //同步命中率相关数据
            PreloadTracker.synchCache()
            //调整任务优先级，并且返回入口命中率，业务命中率，使用频次，业务命中率精度，入口命中率精度，业务依赖度，用于上报埋点。
            let resultTuple = PreloadHitRateManager.shared.adjustPriporty(task: task)
            //判断低端机是否可用
            task.isCancelByLowDevice = !(task.lowDeviceEnable) && PreloadSettingsManager.isLowDevice()
            
            //上报埋点
            PreloadTracker.trackPreloadAwaitExecute(preloadName: task.preloadName,
                                                    priority: task.priority,
                                                    priporityChangeType: task.priporityChangeType,
                                                    preloadId: task.identify,
                                                    diskCache: task.diskCache,
                                                    cacheId: task.diskCacheId,
                                                    bizTypeHitRate: resultTuple.0,
                                                    entranceHitRate: resultTuple.1,
                                                    feedbackCount: resultTuple.2,
                                                    bizTypePrecision: resultTuple.3,
                                                    entrancePrecision: resultTuple.4,
                                                    entranceDependValue: resultTuple.5,
                                                    biz: task.biz, preloadType: task.preloadType,
                                                    isCancelByLowDevice: task.isCancelByLowDevice,
                                                    hasFeedback: task.hasFeedback,
                                                    scope: task.scope,
                                                    moment: task.preloadMoment)

            //任务入队
            let currentQueue: PreloadTaskQueue = self.enqueueByPriority(task: task, priority: task.priority)

            //如果正在监控，或者加入的队列中有任务，或者有更高级别队列中有任务，不需要主动触发调度
            if !(self.dispatcher.isMonitor || currentQueue.getTaskCount() > 1 || self.hasHigherTask(currentQueue: currentQueue)) {
                // 如果有更低级别的队列正在调度，暂停该队列
                if self.hasLowerTask(currentQueue: currentQueue) {
                    self.paushDispatchIng()
                }
                //调度可执行更高级别队列
                PreloadMananger.shared.scheduleQueue.async {
                   if !self.dispatcher.isDispatchIng {
                        self.dispatcher.scheduleHigherQueue()
                    }
                }
            }
        }
    }
    
    //MARK: 注册式预处理任务
    /// 添加注册任务时机监听
    private func startRegisterMonitor(moment: PreloadMoment) {
        let sameMomentTriggers = self.momentTriggers.filter { momentTrigger in
            momentTrigger.momentTriggerType() == moment
        }
        sameMomentTriggers.forEach { momentTrigger in
            momentTrigger.startMomentTriggerMonitor()
            momentTrigger.reciever = self
        }
        PreloadTaskQueuePool.logger.info("preload_startRegisterMonitor_\(moment)")
    }
    
    ///移除指定监听
    func removeRegisterMonitor(moment: PreloadMoment) {
        let sameMomentTriggers = self.momentTriggers.filter { momentTrigger in
            momentTrigger.momentTriggerType() == moment
        }
        sameMomentTriggers.forEach { momentTrigger in
            momentTrigger.removeMomentTriggerMonitor()
        }
    }
    
    ///注册任务触发时机，不重复注册。
    func registMomentTrigger(momentTrigger: MomentTriggerDelegate) {
        let triggers = self.momentTriggers.filter { trigger in
            momentTrigger.momentTriggerType() == trigger.momentTriggerType()
        }
        if triggers.isEmpty {
            self.momentTriggers.append(momentTrigger)
        }
    }
    
    ///添加注册任务
    func addRegisterTask(task: PreloadTask) {
        self.registerTaskArray.append(task)
        self.startRegisterMonitor(moment: task.preloadMoment)
    }
    
    //MARK: 取消，主动调用等逻辑
    ///取消任务
    func cancelTaskById(taskId: TaskIdentify) {
        guard !self.cancelTask(tasks: self.originalTasks, taskId: taskId) else { return }
        self.cancelTask(tasks: self.registerTaskArray, taskId: taskId)
    }
    
    @discardableResult
    func cancelTask(tasks: SafeArray<PreloadTask>, taskId: TaskIdentify) -> Bool {
        var cancelSuccess: Bool = false
        tasks.forEach { task in
            if task.identify == taskId, task.state != .end {
                PreloadTaskQueuePool.logger.info("preload_cancelTask_\(task)")
                //只能取消没有执行完的任务
                task.state = .cancel
                cancelSuccess = true
            }
        }
        return cancelSuccess
    }
    
    ///主动调度任务
    func scheduleTaskById(taskId: TaskIdentify) {
        guard !self.scheduleTaskById(tasks: self.originalTasks, taskId: taskId) else { return }
        guard !self.scheduleTaskById(tasks: self.registerTaskArray, taskId: taskId) else { return }
        self.scheduleTaskById(tasks: PreloadHitRateManager.shared.cancelByLowRateTasks, taskId: taskId)
    }
    
    @discardableResult
    func scheduleTaskById(tasks: SafeArray<PreloadTask>, taskId: TaskIdentify) -> Bool {
        var scheduleSuccess: Bool = false
        tasks.forEach { task in
            if task.identify == taskId, (task.state == .unStart || task.state == .await) {
                PreloadTaskQueuePool.logger.info("preload_scheduleTaskById_\(task)")
                PreloadMananger.shared.taskScheduler.schedulerImmediately(task)
                scheduleSuccess = true
            }
        }
        return scheduleSuccess
    }
    
    ///取消user级别任务
    func cancelUserTask() {
        PreloadTaskQueuePool.logger.info("preload_cancelUserTask")
        self.cancelUserTasks(tasks: self.originalTasks)
        self.cancelUserTasks(tasks: self.registerTaskArray)
    }
    
    private func cancelUserTasks(tasks: SafeArray<PreloadTask>) {
        tasks.forEach { task in
            if task.scope == .user, task.state != .end, task.state != .cancel {
                task.state = .cancel
            }
        }
    }
}

//MARK: PreloadTaskQueueDelegate
extension PreloadTaskQueuePool: PreloadTaskQueueDelegate {
    ///是否可派发
    func canSchedule(priority: PreloadPriority) -> Bool {
        return self.dispatcher.canSchedule(priority: priority)
    }
    
    ///开启监听
    func startMonitor() {
        self.dispatcher.startMonitor()
    }
    
    ///队列派发完成
    func finishQueue(priority: PreloadPriority) {
        PreloadTaskQueuePool.logger.info("preload_finishQueue_\(priority)")
        //当前队列执行完尝试执行其它队列
        self.dispatcher.scheduleHigherQueue()
    }
    
    ///队列暂停派发
    func pauseQueue(priority: PreloadPriority){
        PreloadTaskQueuePool.logger.info("preload_pauseQueue_\(priority)")
    }
}

//MARK: DispatchDelegate
extension PreloadTaskQueuePool: DispatchDelegate {
    //查找当前可调度的最高优先级队列(优先级相对高，并且有任务，并且符合调度条件)，即找即停
    func scheduleHigherQueue(canScheduleAction:(PreloadPriority) -> Bool) -> Bool {
        var canSchedule: Bool = false
        var stopCheck: Bool = false
        self.sortedQueue.forEach { taskQueue in
            guard !stopCheck else { return }
            if taskQueue.getTaskCount() > 0 {
                stopCheck = true
                if canScheduleAction(taskQueue.priority) {
                    canSchedule = true
                }
            }
        }
        return canSchedule
    }
    
    ///开始执行队列任务
    func startDispatch(priority: PreloadPriority) {
        if let taskQueue = self.queuePool[priority] {
            PreloadTaskQueuePool.logger.info("preload_startDispatch_\(priority)")
            taskQueue.state = .run
        }
    }
    
    ///暂停调度
    func pauseDispatch(priority: PreloadPriority) {
        if let taskQueue = self.queuePool[priority] {
            PreloadTaskQueuePool.logger.info("preload_pauseDispatch-\(priority)")
            taskQueue.state = .pause
        }
    }
    
    ///终止调度
    func stopDispatch() {
        PreloadTaskQueuePool.logger.info("preload_stopDispatch")
        self.queuePool.values.forEach { taskQueue in
            taskQueue.state = .cancel
        }
    }

    ///队列是否为空
    func queueIsEmpty() -> Bool {
        let queues = self.queuePool.values.filter { queue in
            queue.getTaskCount() > 0
        }
        return queues.isEmpty
    }
    
    ///完成调度
    func finishDispatch() {
        self.originalTasks.removeAll()
    }
}
    
//MARK: MomentTriggerCallBackDelegate
extension PreloadTaskQueuePool: MomentTriggerCallBackDelegate {
    ///回调添加调度时机
    func callbackMonent(moment: PreloadMoment) {
        //移除监听
        self.removeRegisterMonitor(moment: moment)
        PreloadMananger.shared.registTaskQueue.async {
            //过滤被取消和被主动执行的
            let canSchedulearray = self.registerTaskArray.filter { task in
                task.state == .unStart
            }
            //过滤同一触发时机的task
            let sameMomentarray = canSchedulearray.filter { task in
                task.preloadMoment == moment
            }
            //把过滤后的task添加到调度队列中
            sameMomentarray.forEach { task in
                self.enqueueByPriority(task: task)
            }
            //移除添加到调度中的task和过滤被取消和被主动执行的
            self.registerTaskArray = self.registerTaskArray.filter({ task in
                !sameMomentarray.contains(where: { $0.identify == task.identify }) || task.state == .unStart
            })
        }
    }
}
