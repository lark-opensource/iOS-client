//
//  Event+MonitorCode.swift
//  OPFoundation
//
//  Created by 尹清正 on 2021/3/25.
//

import Foundation

extension OPPerformanceMonitorEvent {
    var monitorCode: OPMonitorCode {
        switch self {
        case .objectLeak: return OPPerformanceMonitorCode.op_object_leaked
        case .objectOvercount: return OPPerformanceMonitorCode.op_object_overcount
        case .memoryWave: return OPPerformanceMonitorCode.op_memory_wave
        }
    }
}
