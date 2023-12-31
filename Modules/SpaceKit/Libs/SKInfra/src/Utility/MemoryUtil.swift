//
//  MemoryUtil.swift
//  SKCommon
//
//  Created by GuoXinyi on 2022/11/29.
//

import Foundation
import UIKit
import SKFoundation

public final class MemoryUtil {
    //内存监控
    public static func reportMemory() -> (success: Bool, usedMb: UInt64, totalMb: UInt64) {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        let usedMb = Float(taskInfo.phys_footprint) / 1048576.0
        let totalMb = Float(ProcessInfo.processInfo.physicalMemory) / 1048576.0

        return (result == KERN_SUCCESS, UInt64(usedMb), UInt64(totalMb))
    }

    //可用内存 MB
    public static func getAvaliableMemorySize() -> UInt64 {
        let memoryInfo = reportMemory()

        var avaliableMemory: UInt64 = 0

        let maxAvaliableMemory = UInt64(Float(memoryInfo.totalMb) * 0.65)

        let usedMb = memoryInfo.success ? memoryInfo.usedMb : 400 //取失败后默认为400mb

        avaliableMemory = maxAvaliableMemory - usedMb
        DocsLogger.info("current Memory total: \(memoryInfo.totalMb) Mb used: \(memoryInfo.usedMb) Mb avaliable: \(avaliableMemory) Mb")

        return avaliableMemory
    }

}

