//
//  ECOCommonMonitorCode.swift
//  ECOInfra
//
//  Created by MJXin on 2021/4/28.
//

import Foundation
class ECOCommonMonitorCode: OPMonitorCode {
    static public let domain = "client.open_platform.common"
    /// 小程序网络trace
    static public let network_rust_trace = ECOCommonMonitorCode(code: 10005, level: OPMonitorLevelNormal, message: "network_rust_trace")
    
    private init(code: Int, level:  OPMonitorLevel, message: String) {
        super.init(domain: ECOCommonMonitorCode.domain, code: code, level: level, message: message)
    }
}
