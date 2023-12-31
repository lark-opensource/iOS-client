//
//  Event+Sampling.swift
//  OPFoundation
//
//  Created by 尹清正 on 2021/3/18.
//

import Foundation

/// 扩展OPPerformanceMonitorEvent，提供采样参数
extension OPPerformanceMonitorEvent {

    var samplingRate: Double {
        switch self {
        case .objectLeak: return OPPerformanceMonitorConfigProvider.objectLeakedSamplingRate
        case .objectOvercount: return OPPerformanceMonitorConfigProvider.objectOvercountSamplingRate
        case .memoryWave: return OPPerformanceMonitorConfigProvider.memoryWaveSamplingRate
        }
    }

    var samplingOffset: Double {
        switch self {
        case .objectLeak: return OPPerformanceMonitorConfigProvider.objectLeakedSamplingOffset
        case .objectOvercount: return OPPerformanceMonitorConfigProvider.objectOvercountSamplingOffset
        case .memoryWave: return OPPerformanceMonitorConfigProvider.memoryWaveSamplingOffset
        }
    }

}
