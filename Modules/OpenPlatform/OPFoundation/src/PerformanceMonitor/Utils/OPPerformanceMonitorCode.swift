//
//  OPPerformanceMonitorCode.swift
//  OPFoundation
//
//  Created by liuyou on 2021/4/22.
//

import Foundation
import ECOProbe

@objcMembers
final class OPPerformanceMonitorCode: OPMonitorCode {

    /// 检测到有对象内存泄漏发生
    public static let op_object_leaked = OPPerformanceMonitorCode(code: 10001, level: OPMonitorLevelWarn, message: "op_object_leaked")

    /// 检测到对象实例数量超出限制
    public static let op_object_overcount = OPPerformanceMonitorCode(code: 10002, level: OPMonitorLevelWarn, message: "op_object_overcount")

    /// 检测到指定时期内内存波动过大
    public static let op_memory_wave = OPPerformanceMonitorCode(code: 10003, level: OPMonitorLevelWarn, message: "op_memory_wave")

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: OPPerformanceMonitorCode.domain, code: code, level: level, message: message)
    }

    public static let domain = "client.open_platform.common.performance"
}
