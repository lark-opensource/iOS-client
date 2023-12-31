//
//  WorkplaceMonitorValue.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/6/30.
//

import Foundation
import ECOInfra
import RustPB

enum WorkplaceMonitorResultValue: String {
    case success
    case fail
    case cancel
    case timeout

    var rawValue: String {
        switch self {
        case .success:
            return OPMonitorEventValue.success
        case .fail:
            return OPMonitorEventValue.fail
        case .cancel:
            return OPMonitorEventValue.cancel
        case .timeout:
            return OPMonitorEventValue.timeout
        }
    }
}

/// 工作台门户渲染类型
enum WorkplaceMonitorPortalRenderType: String {
    /// 冷启动
    case cold_boot
    /// 错误重试
    case error_retry
}

extension Rust.NetStatus {
    var monitorValue: String {
        switch self {
        case .excellent:
            return "excellent"
        case .evaluating:
            return "evaluating"
        case .weak:
            return "weak"
        case .netUnavailable:
            return "netUnavailable"
        case .serviceUnavailable:
            return "serviceUnavailable"
        case .offline:
            return "offline"
        @unknown default:
            return "unknown"
        }
    }
}
