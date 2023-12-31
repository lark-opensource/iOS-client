//
//  SecurityComplianceService.swift
//  LarkSecurityComplianceInterface
//
//  Created by ByteDance on 2023/9/12.
//

import Foundation

/// 当前无权限页面状态
public enum NoPermissionState: Int {
    /// 闲置
    case idle
    /// 受限
    case limited
}

public protocol SecurityComplianceService {
    /// 当前无权限页面状态
    var state: NoPermissionState { get }
}
