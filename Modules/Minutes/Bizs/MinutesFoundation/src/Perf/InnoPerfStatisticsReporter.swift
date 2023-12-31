//
//  InnoPerfStatisticsReporter.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/7/15.
//

import Foundation
import LKCommonsTracker
import Heimdallr

class InnoPerfStatisticsReporter: Reporter {
    var category: [String: Any] = [:]
    var extra: [String: Any] = [:]

    let queue: DispatchQueue

    var currentWorkItem: DispatchWorkItem?

    var cpu = CPUMonitor()
    var memory = MemoryMonitor()

    @SyncedSetting private var config: VCInnoPerfConfig?
    // disable-lint: magic number
    var period: Int {
        return config?.reportInterval ?? 20
    }
    // enable-lint: magic number

    var appMemBase: UInt64?
    var sysMemBase: UInt64?

    var metric: [String: Any] {
        let cpuUsage = cpu.cpuUsage()
        let memoryUsage = memory.memoryUsage()
        var value: [String: Any] = ["app_cpu_usage": cpuUsage.process,
                                    "sys_cpu_usage": cpuUsage.system,
                                    "app_mem_usage": memoryUsage.appUsed,
                                    "sys_mem_usage": memoryUsage.sysUsed,
                                    "total_mem": memoryUsage.total]
        value["app_mem_base"] = appMemBase
        value["sys_mem_base"] = sysMemBase
        return value
    }

    init(workQueue: DispatchQueue) {
        queue = workQueue
    }

    func track() {
        let metric = self.metric
        var extra = self.extra
        extra["powerSaving"] = ProcessInfo.processInfo.isLowPowerModeEnabled

        var category = self.category
        category["sub_scene"] = HMDUITrackerManager.shared().scene
        #if DEBUG
        InnoPerfMonitor.logger.debug("inno_perf_statistics metric: \(metric), category: \(category), extra: \(extra)")
        #else
        let event = SlardarEvent(name: "inno_perf_statistics", metric: metric, category: category, extra: extra)
        Tracker.post(event)
        #endif
    }

    func perform() {
        let workItem = DispatchWorkItem { [weak self] in
            self?.track()
            self?.perform()
        }

        queue.asyncAfter(deadline: .now() + .seconds(period), execute: workItem)

        currentWorkItem = workItem
    }

    func updateBase() {
        let memoryUsage = memory.memoryUsage()
        appMemBase = memoryUsage.appUsed
        sysMemBase = memoryUsage.sysUsed
    }

    func clearBase() {
        appMemBase = nil
        sysMemBase = nil
    }

    func fire(keepAlive: Bool, category: [String: Any]) {

        currentWorkItem?.cancel()
        currentWorkItem = nil

        queue.async {
            self.track()
            self.category = category
            if keepAlive {
                self.updateBase()
                self.perform()
            } else {
                self.clearBase()
            }
        }

    }

    func update(extra: [String: Any]) {
        queue.async {
            self.extra = extra
        }
    }
}
