//
//  CPULauncherObserver.swift
//  Launcher
//
//  Created by nine on 2020/1/9.
//  Copyright © 2020 nine. All rights reserved.
//

import Foundation
import LarkMonitor
import RunloopTools

class CPULauncherObserver: LauncherObserver {
    var identifier: LauncherSystemStateKey = .cpu

    // LKCExceptionCPUMonitor.callback
    @ThreadSafe private var monitor: Any?

    // satisfy the number of leisure time conditions
    private var satisfyTimes: Int32 = 0

    /// 当前CPU核数
    private lazy var core: Int = {
        return ProcessInfo.processInfo.activeProcessorCount
    }()

    public func reset() {
       _registerService()
    }

    public func clear() {
        _unRegisterService()
        OSAtomicCompareAndSwap32Barrier(satisfyTimes, 0, &satisfyTimes) //set zero
    }

    public func isLeisure() -> Bool {
        guard self.monitor != nil else {
            _registerService()
            return false
        }
        guard Launcher.shared.config.leisureCondition[identifier] != nil else {
            return true
        }
        if satisfyTimes == Launcher.shared.config.leisureTimes {
            //开始执行任务之后需要重置闲时计算器
            OSAtomicCompareAndSwap32Barrier(satisfyTimes, 0, &satisfyTimes) //set zero
            return true
        }
        return false
    }

    private func handleCurCpuUsage(_ cpuUsage: Double) {
        guard let condition = Launcher.shared.config.leisureCondition[identifier] else { return }
        if condition >= cpuUsage, satisfyTimes < Launcher.shared.config.leisureTimes {
            OSAtomicIncrement32Barrier(&satisfyTimes) // auto increment
        } else if condition < cpuUsage {
            OSAtomicCompareAndSwap32Barrier(satisfyTimes, 0, &satisfyTimes) //set zero
        }
    }
}

extension CPULauncherObserver {
    private func _registerService() {
        guard monitor == nil else {
            return
        }
        let timeInterval = Int32(Launcher.shared.config.monitorInterval) >= 1 ? Int32(Launcher.shared.config.monitorInterval) : 1 //采样率必须大于等于1
        monitor = LKCExceptionCPUMonitor.registCallback({ [weak self] (value) in
            guard let self = self else { return }
            self.handleCurCpuUsage(value / Double(self.core))
            }, timeInterval: timeInterval)
    }

    private func _unRegisterService() {
        guard let monitor = self.monitor else { return }
        DocsLogger.info("DocsLauncher unRegisterCPUMonitor")
        LKCExceptionCPUMonitor.unRegistCallback(monitor)
        self.monitor = nil
    }
}
