//
//  PreloadScheduler.swift
//  Lark
//
//  Created by huanglx on 2023/1/31.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//

import Foundation
import LKCommonsLogging
import LarkDowngrade
import ThreadSafeDataStructure

/// task执行线程调度器
class PreloadScheduler {
    //是否是核心场景
    private var isCoreScene: Bool = false
    //CPU和内存是否满足降级条件
    private var isDownGrade: Bool = false
    //是否在后台
    private var isBackground: Bool = false
    //队列缓存池
    private var taskBufferArray: SafeArray<PreloadTask> = [] + .readWriteLock
    //队列索引
    var queueIndex = 0
    //防饿死机制是否开启
    var preventStarveIsOpen: Bool = false
    //防饿死监听timer
    var monitorTimer: Timer?
    
    //队列是否暂停-核心场景和降级只要有一个满足就会暂停。
    private var queueIsSuspended: Bool {
        get {
            //后台暂停
            guard !self.isBackground else {
                return true
            }
            //防饿死机制开启，恢复队列
            guard !self.preventStarveIsOpen else {
                self.isCoreScene = false
                self.isDownGrade = false
                return false
            }
            return self.isCoreScene || self.isDownGrade
        }
    }
    
    private static var logger = Logger.log(PreloadScheduler.self)
    
    // 串行队列
    lazy var serialQueue: OperationQueue = {
        return self.getSerialQueue()
    }()
    
    //一次监听检查周期次数，判断是否触发防饿死机制
    var monitorCycleCount: Int = 0 {
        didSet {
            if monitorCycleCount > PreloadSettingsManager.preventStarveCycleCount() { //超过n次监听周期都没有恢复，触发防饿死机制，移除监听，并且解除CPU和内存的限制，m秒后恢复限制。
                PreloadScheduler.logger.info("preload_preventStarveIsOpen")
                self.preventStarveIsOpen = true
                //移除防饿死监听
                self.removeStarveMonitor()
                //执行队列
                self.tryPauseOrRecoverQueue()
                DispatchQueue.main.asyncAfter(deadline: .now() + PreloadSettingsManager.preventStarveOpenTime()) { [weak self] in
                    //关闭防饿死机制
                    PreloadScheduler.logger.info("preload_preventStarveIsClose")
                    self?.preventStarveIsOpen = false
                }
            }
        }
    }
    
    /// 在对应线程执行
    @discardableResult
    func scheduler(_ task: PreloadTask) -> Bool {
        guard !self.queueIsSuspended else {
            //如果队列处于挂起状态，把任务暂存到缓冲池中
            self.taskBufferArray.append(task)
            return false
        }
        task.state = .start
        PreloadTracker.trackPreloadExecute(preloadId: task.identify)
        switch task.scheduler {
        case .main:
            DispatchQueue.main.mainAsyncIfNeeded {
                task.exec()
            }
        case .concurrent:
            let operationQueue: OperationQueue = self.getSerialQueueFromPool()
            operationQueue.addOperation {
                task.exec()
            }
        case .async:
            self.serialQueue.addOperation {
                task.exec()
            }
        }
        return true
    }
    
    /// 立刻执行
    func schedulerImmediately(_ task: PreloadTask) {
        task.state = .start
        PreloadTracker.trackPreloadExecute(preloadId: task.identify)
        task.exec()
    }
    
    //MARK: 串行队列线程池
    //串行队列池
    private var serialQueuePool: SafeArray<OperationQueue> = [] + .readWriteLock
    
    ///创建一个串行队列
    private func getSerialQueue() -> OperationQueue {
        let op = OperationQueue()
        op.qualityOfService = .userInteractive
        op.name = "preloadQueue_\(queueIndex)"
        //最大并发数是1，相当于串行
        op.maxConcurrentOperationCount = 1
        PreloadScheduler.logger.info("preload_getSerialQueue")
        queueIndex += 1
        return op
    }
    
    /*
     从队列池中获取一个队列
     查找符合条件的队列查找规则
     -如果队列池是空，创建一个队列。
     -如果队列数超过最大限制数，添加到等待队列最少的那个队列中
     -如果队列数没有超过最大的限制
        -当前队列都达到最大限制数，新创建队列，添加到新队列中。
        -当前队列有不满足最大限制数的，添加到等待队列中最小的队列中。
     */
    private func getSerialQueueFromPool() -> OperationQueue {
        var targetQueue: OperationQueue
        if serialQueuePool.count == 0 { //队列池为空
            targetQueue = self.getSerialQueue()
            serialQueuePool.append(targetQueue)
            return targetQueue
        }
        if serialQueuePool.count >= PreloadSettingsManager.getMaxQueueCount() { //达到最大队列限制
            targetQueue = self.findMinQueue(queuePool: self.serialQueuePool)
            return targetQueue
        } else {
            targetQueue = self.findMinQueue(queuePool: self.serialQueuePool)
            //如果最小的队列个数超过了阈值，新开一个队列
            if targetQueue.operationCount >= PreloadSettingsManager.getMaxOperationCount() {
                targetQueue = self.getSerialQueue()
                serialQueuePool.append(targetQueue)
            }
            return targetQueue
        }
    }
    
    ///获取当前队列池中排队最少的队列
    private func findMinQueue(queuePool: SafeArray<OperationQueue>) -> OperationQueue {
        var targetQueue: OperationQueue = queuePool[0]
        queuePool.forEach { queue in
            if targetQueue.operationCount > queue.operationCount {
                targetQueue = queue
            }
        }
        PreloadScheduler.logger.info("preload_findMinQueue_operationCount_\(targetQueue.operationCount)")
        return targetQueue
    }
    
    //MARK: 动态降级
    //注册动态降级
    func registerDynamicDowngrade() {
        //只有允许监听才生效
        guard PreloadSettingsManager.enableChecker() else {
            return
        }
        //采用预加载高优先级任务的阈值
        let cpuAndMemoryValue = PreloadSettingsManager.getCpuAndMemoryValue()
        let cpuLimit_hight = cpuAndMemoryValue["cpuLimit_hight"] as? Double ?? 0.9
        let memoryLimit_hight = cpuAndMemoryValue["memoryLimit_hight"] as? Int ?? 100
        
        //配置动态降级的规则
        //CPU和内存是否满足执行条件
        let cpuRule = LarkDowngradeRuleInfo(ruleList: [.overDeviceCPU: cpuLimit_hight], time: 1)
        let memoryRule = LarkDowngradeRuleInfo(ruleList: [.overMemory: Double(memoryLimit_hight)], time: 1)
        let rules = LarkDowngradeRule(rules: [.overload: [cpuRule, memoryRule], .normal: [cpuRule, memoryRule]])
        let config = LarkDowngradeConfig(rules: [rules])
        
        //注册动态降级监听
        LarkDowngradeService.shared.addObserver(key: "lark_preload_scheduler", config: config) { [weak self](_)in
            //动态降级开启
            PreloadScheduler.logger.info("preload_dynamic_downgroade_start")
            self?.isDownGrade = true
            self?.tryPauseOrRecoverQueue()
        } doCancel: { _ in
        } doNormal: { [weak self](_) in
            //动态降级恢复
            PreloadScheduler.logger.info("preload_dynamic_downgroade_end")
            self?.isDownGrade = false
            self?.tryPauseOrRecoverQueue()
        }
    }
    
    ///尝试暂停/恢复队列
    let queuelock: NSLock = NSLock()
    func tryPauseOrRecoverQueue() {
        queuelock.lock()
        defer {
            queuelock.unlock()
        }
        if self.queueIsSuspended { //暂停队列
            //后台暂停任务
            guard !self.isBackground else {
                PreloadScheduler.logger.info("preload_scheduler_suspended_byBackground")
                self.serialQueuePool.forEach { queue in
                    queue.isSuspended = true
                }
                self.serialQueue.isSuspended = true
                return
            }
            //触发了防饿死，不暂停
            guard !self.preventStarveIsOpen else {
                return
            }
            //开始饿死监听
            self.startStarveMonitor()
            PreloadScheduler.logger.info("preload_scheduler_suspended")
            self.serialQueuePool.forEach { queue in
                queue.isSuspended = true
            }
            self.serialQueue.isSuspended = true
        } else { //恢复队列
            //移除饿死监听
            self.removeStarveMonitor()
            PreloadScheduler.logger.info("preload_scheduler_resume")
            self.serialQueuePool.forEach { queue in
                queue.isSuspended = false
            }
            self.serialQueue.isSuspended = false
            //释放缓冲池
            self.releaseBufferArray()
        }
    }
    
    ///释放缓冲池任务
    func releaseBufferArray() {
        self.doFirstTask()
    }
    
    ///调度第一个任务
    private func doFirstTask() {
        if let task = self.taskBufferArray.first {
            let isActive = self.scheduler(task)
            self.doNextTask(isActive: isActive)
        }
    }
    
    ///执行下一个任务
    private func doNextTask(isActive: Bool) {
        if !(self.taskBufferArray.isEmpty) {
            _ = self.taskBufferArray.remove(at: 0)
        }
        if isActive {
            self.doFirstTask()
        }
    }
    
    //MARK:  防饿死监听器
    //开始监听-2秒监听一次
    func startStarveMonitor() {
        DispatchQueue.main.async {
            //只有preventStarveCycleCount大于0才开启防饿死监听
            guard self.monitorTimer == nil, PreloadSettingsManager.preventStarveCycleCount() > 0 else {
                return
            }
            self.monitorTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.monitorCallback), userInfo: nil, repeats: true)
            if let curTimer: Timer = self.monitorTimer {
                RunLoop.main.add(curTimer, forMode: .common)
            }
        }
    }
    
    //移除防饿死监听
    func removeStarveMonitor() {
        if monitorTimer != nil {
            self.monitorCycleCount = 0
            monitorTimer?.invalidate()
            monitorTimer = nil
        }
    }
    
    //监听回调
    @objc
    func monitorCallback() {
        self.monitorCycleCount += 1
    }
    
    //MARK: 监听进入前后台处理
    ///切换到后台暂停队列
    func applicationDidEnterBackground() {
        guard PreloadSettingsManager.pauseByBackground() else {
            return
        }
        self.isBackground = true
        self.tryPauseOrRecoverQueue()
    }
    
    ///切换到前台恢复队列
    func applicationWillEnterForeground() {
        guard PreloadSettingsManager.pauseByBackground() else {
            return
        }
        self.isBackground = false
        self.tryPauseOrRecoverQueue()
    }
}

///核心场景监听
extension PreloadScheduler: CoreSceneDelegate {
    /*
     监听核心场景状态变化
        -param: 是否是核心场景
     */
    func coreSceneDidChange(isCoreScene: Bool) {
        guard PreloadSettingsManager.enableChecker() else {
            return
        }
        self.isCoreScene = isCoreScene
        self.tryPauseOrRecoverQueue()
    }
}

extension DispatchQueue {
    /// 确保在主队列，如果当前是主队列，不执行async
    @inline(__always)
    func mainAsyncIfNeeded(_ block: @escaping () -> Void) {
        if self === DispatchQueue.main && Thread.isMainThread {
            block()
        } else {
            async { block() }
        }
    }
}
