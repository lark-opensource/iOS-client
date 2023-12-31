//
//  LogReportService.swift
//  LarkSecurityComplianceInterface
//
//  Created by ByteDance on 2023/8/29.
//

import Foundation

public protocol LogReportService {
    /// 安全SDK上报决策日志
    /// - Parameter validateLogInfos: 日志info信息数组
    func report(_ validateLogInfos: [ValidateLogInfo])
    
    /// 安全SDK上报待删除日志info，删除服务端存储的日志信息
    /// - Parameter validateLogInfos: 日志info信息数组
    func delete(_ validateLogInfos: [ValidateLogInfo])
    
    /// 策略集是否应该生成对应的上报日志info
    /// - Parameter policySetKey: 策略集名称
    /// - Returns: 是否应该生成日志
    func shouldGenerateLog(pointKey: String, policySetKey: String) -> Bool
}
