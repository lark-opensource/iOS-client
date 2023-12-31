//
//  DeviceMemory.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/7/22.
//

import Foundation

/// 设备内存
internal enum DeviceMemory {

    /// 总容量(单位: Bytes)
    internal static var totalSize: Int64 {
        // 模拟器不检测具体可用内存
#if targetEnvironment(simulator)
        return .max
#else
        let size = Int64(ProcessInfo.processInfo.physicalMemory)
        assert(size > 0, "Incorrect calculation of total device memory size.")
        return size
#endif
    }

    /// 可用内存(单位: Bytes)
    internal static var availableSize: Int64 {
        // 模拟器不检测具体可用内存
#if targetEnvironment(simulator)
        return .max
#else
        var page_size: vm_size_t = 0

        let host_port = mach_host_self()
        var host_size = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
        host_page_size(host_port, &page_size)

        var vm_stat = vm_statistics_data_t()
        withUnsafeMutablePointer(to: &vm_stat) { vm_stat_pointer in
            vm_stat_pointer.withMemoryRebound(to: integer_t.self, capacity: Int(host_size)) {
                if host_statistics(host_port, HOST_VM_INFO, $0, &host_size) != KERN_SUCCESS {
                    print("Fetch vm statistics failed.")
                }
            }
        }

        /* Stats in bytes */
//        let mem_used: Int64 = Int64(vm_stat.active_count +
//                                    vm_stat.inactive_count +
//                                    vm_stat.wire_count) * Int64(pagesize)
        let mem_free = Int64(vm_stat.free_count) * Int64(page_size)
        return mem_free
#endif
    }
}
