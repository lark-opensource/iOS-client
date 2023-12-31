//
//  OPPerformanceInfoAllocator.swift
//  EEMicroAppSDK
//
//  Created by 尹清正 on 2021/3/19.
//

import Foundation

/// 埋点字段的key
fileprivate let cpuUsageKey = "cpu_usage"
fileprivate let memoryUsageKey = "memory_usage"

/// 负责收集与当前系统环境信息
struct OPPerformanceInfoAllocator: OPMemoryInfoAllocator {

    func allocateMemoryInfo(with target: NSObject, monitor: OPMonitor) {
        let cpuUsage = OPPerformanceUtil.cpuUsage()
        let memoryInByte = OPPerformanceUtil.usedMemoryInMB()

        _ = monitor.addMetricValue(cpuUsageKey, cpuUsage)
        _ = monitor.addMetricValue(memoryUsageKey, memoryInByte)
    }
}
