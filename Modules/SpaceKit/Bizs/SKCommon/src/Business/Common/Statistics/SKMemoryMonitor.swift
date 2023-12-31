//
//  MemoryMonitor.swift
//  SKCommon
//
//  Created by zengsenyuan on 2022/8/18.
//  


import SKFoundation
import Heimdallr

public final class SKMemoryMonitor {
    public static let memoryWarningNotification = KHMDMemoryMonitorMemoryWarningNotificationName

    /// 打内存日志
    /// - Parameters:
    ///   - monitorTime: 触发日志时间
    ///   - delay: 延迟多久时间
    ///   - extraInfo: 额外参数
    public static func logMemory(when monitorTime: String,
                                 delay: TimeInterval = 0,
                                 extraInfo: [String: Any]? = nil,
                                 component: String? = nil,
                                 fileName: String = #fileID,
                                 funcName: String = #function,
                                 funcLine: Int = #line) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let memory = getMemory()
            DocsLogger.info("[doc-memory-monitor] " + monitorTime + " appMemory: \(memory.appMemory), sysUseMemory: \(memory.sysUseMemory)",
                            extraInfo: extraInfo,
                            component: component,
                            fileName: fileName,
                            funcName: funcName,
                            funcLine: funcLine)
        }
    }
    
    
    public static func getMemory() -> (appMemory: UInt64, sysUseMemory: UInt64, totalMemory: UInt64) {
        let memoryBytes = hmd_getMemoryBytes()
        let appMemory = memoryBytes.appMemory / 1048576
        let sysUseMemory = memoryBytes.usedMemory / 1048576
        let totalMemory = memoryBytes.totalMemory / 1048576
        return (appMemory, sysUseMemory, totalMemory)
    }
}
