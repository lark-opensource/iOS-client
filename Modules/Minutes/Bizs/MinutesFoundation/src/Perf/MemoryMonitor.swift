//
//  MemoryMonitor.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/7/14.
//

import Foundation

public struct MemoryUsage {
    public let appUsed: UInt64
    public let sysUsed: UInt64
    public var total: UInt64 {
        ProcessInfo.processInfo.physicalMemory
    }
}

public final class MemoryMonitor {

    func memoryUsage() -> MemoryUsage {
        var taskInfo = task_vm_info_data_t()
        let maxTaskVmInfoSize = MemoryLayout<task_vm_info_data_t>.stride/MemoryLayout<integer_t>.stride
        var count = mach_msg_type_number_t(maxTaskVmInfoSize)
        let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: maxTaskVmInfoSize) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }

        var used: UInt64 = 0
        if result == KERN_SUCCESS {
            used = UInt64(taskInfo.phys_footprint)
        } else {
            InnoPerfMonitor.logger.warn("task info failed: \(result)")
        }

        // Initialize a blank vm_statistics_data_t
        var vmStat = vm_statistics_data_t()
        let maxHostVMStatSize = MemoryLayout<vm_statistics_data_t>.stride/MemoryLayout<integer_t>.stride
        var hostSize = mach_msg_type_number_t(maxHostVMStatSize)
        var pageSize: vm_size_t = 0
        var sysUsed: UInt64 = 0

        host_page_size(mach_task_self_, &pageSize)
        // Get a raw pointer to vm_stat
        let err: kern_return_t = withUnsafeMutablePointer(to: &vmStat) {
            $0.withMemoryRebound(to: integer_t.self, capacity: maxHostVMStatSize) {
                return host_statistics(mach_host_self(), HOST_VM_INFO, $0, &hostSize)
            }
        }

        // Now take a look at what we got and compare it against KERN_SUCCESS
        if err == KERN_SUCCESS {
            sysUsed = UInt64(vmStat.active_count + vmStat.wire_count) * UInt64(pageSize)
        } else {
            InnoPerfMonitor.logger.warn("host statistics failed: \(err)")
        }

        return MemoryUsage(appUsed: used, sysUsed: sysUsed)
    }
}
