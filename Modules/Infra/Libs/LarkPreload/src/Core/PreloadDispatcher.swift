//
//  PreloadDispatcher.swift
//  Lark
//
//  Created by huanglx on 2023/1/17.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//

import Foundation
import LKCommonsLogging
import LarkDowngrade

///调度代理
protocol DispatchDelegate: AnyObject {
    ///开始调度
    func startDispatch(priority: PreloadPriority)
    ///暂停调度
    func pauseDispatch(priority: PreloadPriority)
    ///终止调度
    func stopDispatch()
    ///完成调度
    func finishDispatch()
    ///获取可执行的最高优先级队列
    func scheduleHigherQueue(canScheduleAction:(PreloadPriority) -> Bool) -> Bool
    ///队列是否为空
    func queueIsEmpty() -> Bool
}

///监听代理
protocol MoinitorDelegate: AnyObject {
    //监听回调
    func callbackMonitor()
    
    //触发防饿死
    func trigggerPreventStarve(isOpen: Bool)
}

///预加载调度器
class PreloadDispatcher {
    //监听器
    lazy var monitor: PreloadMonitor = { return PreloadMonitor() }()
    //是否正在监听
    var isMonitor: Bool = false
    //是否正在派发
    var isDispatchIng: Bool = false
    //防饿死机制是否开启
    var preventStarveIsOpen: Bool = false
    //回调代理
    weak var reciever: DispatchDelegate?
    
    private static var logger = Logger.log(PreloadDispatcher.self)
    
    //MARK: 性能监听
    ///开始监控-只有当前不满足预加载条件时才开启监控，当满足后停止监控
    func startMonitor() {
        guard !self.isMonitor else { return }
        self.isMonitor = true
        PreloadDispatcher.logger.info("preload_startMonitor")
        DispatchQueue.main.async {
            self.monitor.reciever = self
            self.monitor.startMonitor()
        }
    }
    
    ///移除监听
    private func removeMonitor() {
        guard self.isMonitor else { return }
        self.monitor.removeMonitor()
        self.isMonitor = false
        PreloadDispatcher.logger.info("preload_removeMonitor")
    }
    
    //MARK: 队列调度
    ///是否执行调度
    func canSchedule(priority: PreloadPriority) -> Bool {
        guard PreloadSettingsManager.enableChecker() else {
            return true
        }
        let cpuAndMemoryValue: [String: Any] = PreloadSettingsManager.getCpuAndMemoryValue()
        //判断不同的优先级任务是否满足触发条件。
        switch priority {
            case .low: do {
                let cpuLimit_low = cpuAndMemoryValue["cpuLimit_low"] as? Double ?? 0.8
                let memoryLimit_low = cpuAndMemoryValue["memoryLimit_low"] as? Int ?? 200
                return self.canSchedule(cpuLimit: cpuLimit_low, memoryLimit: memoryLimit_low)
            }
            case .middle: do {
                let cpuLimit_middle = cpuAndMemoryValue["cpuLimit_middle"] as? Double ?? 0.85
                let memoryLimit_middle = cpuAndMemoryValue["memoryLimit_middle"] as? Int ?? 150
                return self.canSchedule(cpuLimit: cpuLimit_middle, memoryLimit: memoryLimit_middle)
            }
            case .hight: do {
                let cpuLimit_hight = cpuAndMemoryValue["cpuLimit_hight"] as? Double ?? 0.9
                let memoryLimit_hight = cpuAndMemoryValue["memoryLimit_hight"] as? Int ?? 100
                return self.canSchedule(cpuLimit: cpuLimit_hight, memoryLimit: memoryLimit_hight)
            }
        }
    }
    
    private func canSchedule(cpuLimit: Double, memoryLimit: Int) -> Bool {
        //触发防饿死机制，不做调度检查。
        guard !self.preventStarveIsOpen else {
            return true
        }
        //如果核心场景不进行预加载
        guard !CoreSceneMointor.isCoreScene else {
            return false
        }
        //CPU和内存是否满足执行条件
        let cpuRule = LarkDowngradeRuleInfo(ruleList: [.overDeviceCPU: cpuLimit], time: 1)
        let memoryRule = LarkDowngradeRuleInfo(ruleList: [.overMemory: Double(memoryLimit)], time: 1)
        let rules = LarkDowngradeRule(rules: [.overload: [cpuRule,memoryRule]])
        let config = LarkDowngradeConfig(rules: [rules])
        var canSchedule = true
        LarkDowngradeService.shared.Downgrade(key: "lark_preload_dispatcher",config: config) { _ in
            canSchedule = false
        } doNormal: { _ in
            canSchedule = true
        }
        return canSchedule
    }
        
    /// 调度最高级别队列 高->低
    func scheduleHigherQueue() {
        self.isDispatchIng = true
        //队列为空,队列调度完成
        guard let isEmpty = self.reciever?.queueIsEmpty(), !isEmpty else {
            self.isDispatchIng = false
            self.removeMonitor()
            self.reciever?.finishDispatch()
            return
        }
        //执行当前可执行的最高优先级
        let result = self.reciever?.scheduleHigherQueue { priority in
            return self.scheduleQueueIfNeed(priority: priority)
        }
        //如果没有可执行的队列,开启监听
        if result == false {
            self.startMonitor()
        }
    }
    
    ///调度可执行的队列
    private func scheduleQueueIfNeed(priority: PreloadPriority) -> Bool {
        var scheduleSuccess: Bool = false
        if self.canSchedule(priority: priority) {
            self.removeMonitor()
            self.reciever?.startDispatch(priority: priority)
            scheduleSuccess = true
        }
        return scheduleSuccess
    }
}

//MARK: MoinitorDelegate
extension PreloadDispatcher: MoinitorDelegate {
    //回调监听,调度最高级别队列
    func callbackMonitor() {
        PreloadDispatcher.logger.info("preload_callbackMonitor")
        PreloadMananger.shared.scheduleQueue.async {
            self.scheduleHigherQueue()
        }
    }
    
    //触发防饿死机制
    func trigggerPreventStarve(isOpen: Bool) {
        self.preventStarveIsOpen = isOpen
        PreloadDispatcher.logger.info("preload_trigggerPreventStarve_\(isOpen)")
    }
}
