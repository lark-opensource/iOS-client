//
//  OPMonitorCodeProtocol.swift
//  ECOProbeMeta
//
//  Created by Crazy凡 on 2023/3/24.
//

import Foundation

@available(*, renamed: "OPMonitorLevel.trace")
public let OPMonitorLevelTrace   = OPMonitorLevel.trace

@available(*, renamed: "OPMonitorLevel.normal")
public let OPMonitorLevelNormal  = OPMonitorLevel.normal

@available(*, renamed: "OPMonitorLevel.warn")
public let OPMonitorLevelWarn    = OPMonitorLevel.warn

@available(*, renamed: "OPMonitorLevel.error")
public let OPMonitorLevelError   = OPMonitorLevel.error

@available(*, renamed: "OPMonitorLevel.fatal")
public let OPMonitorLevelFatal   = OPMonitorLevel.fatal

@objc
public enum OPMonitorLevel: UInt {
    case trace = 1 // 用于记录一些运行状况，默认不会上报，在一定时机会进行上报（例如发生 Error 时）
    case normal = 2 // 正常级别的埋点，默认上报
    case warn = 3 // 发生不严重的异常，默认上报
    case error = 4 // 发生异常，默认上报
    case fatal = 5 // 发生致命异常
}

@objc
public protocol OPMonitorCodeProtocol: NSObjectProtocol {
    /// 业务域，参与ID计算
    var domain: String { get }

    /// 业务域内唯一编码 code，参与ID计算
    var code: Int { get }

    /// 唯一识别ID，格式为：{version}-{domain}-{code}
    @objc(ID)
    var id: String { get }

    /// 建议级别（不代表最终级别），不参与ID计算
    var level: OPMonitorLevel { get }

    /// 相关信息，不参与ID计算
    var message: String { get }
}
