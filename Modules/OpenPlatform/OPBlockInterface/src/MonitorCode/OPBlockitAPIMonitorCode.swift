//
//  OPBlockitAPIMonitorCode.swift
//  OPBlockInterface
//
//  Created by xiangyuanyuan on 2022/5/30.
//

import Foundation
import LarkOPInterface

@objcMembers
public final class OPBlockitAPIMonitorCode: OPMonitorCode {
    
    /** hideBlockLoading-配置信息错误 */
    public static let hideBlockLoading_config_missing = OPBlockitAPIMonitorCode(domain: domain, code: 2400001, level: OPMonitorLevelError, message: "not use loading")
    
    static public let domain = "client.open_platform.blockit.api"
}
