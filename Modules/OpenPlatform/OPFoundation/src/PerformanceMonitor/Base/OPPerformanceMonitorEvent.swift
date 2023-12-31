//
//  OPPerformanceMonitorEvent.swift
//  OPFoundation
//
//  Created by 尹清正 on 2021/3/18.
//

import Foundation

/// 需要监控的指标
@objc public enum OPPerformanceMonitorEvent: UInt, CaseIterable {
    /// 内存泄漏
    case objectLeak
    /// 内存波动
    case memoryWave
    /// 对象实例数量超限
    case objectOvercount
}
