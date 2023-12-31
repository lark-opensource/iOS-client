//
//  OpenPlatformMonitorDefine.swift
//  LarkOpenPlatform
//
//  Created by yinyuan on 2020/5/24.
//

import Foundation
import LarkOPInterface

/// Monitor Code 定义
/// - 修改请先修改 [统一定义文档](https://bytedance.feishu.cn/sheets/shtcnCCboz4CUWBUtZkdmZV0PLb?table=tblhdeAY8y&view=vewDYgteNU#ve29xQ)
@objcMembers
final class OpenPlatformMonitorCode: OPMonitorCode {

    /// 不合法的参数
    static public let unknown_error = OpenPlatformMonitorCode(code: 10_000, level: OPMonitorLevelError, message: "unknown_error")
    /// 成功
    static public let success = OpenPlatformMonitorCode(code: 10_001, level: OPMonitorLevelNormal, message: "success")
    /// 取消
    static public let cancel = OpenPlatformMonitorCode(code: 10_002, level: OPMonitorLevelWarn, message: "cancel")
    /// 超时
    static public let timeout = OpenPlatformMonitorCode(code: 10_003, level: OPMonitorLevelError, message: "timeout")

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: OpenPlatformMonitorCode.domain, code: code, level: level, message: message)
    }

    /// domain
    static public let domain = "client.open_platform.common"
}
