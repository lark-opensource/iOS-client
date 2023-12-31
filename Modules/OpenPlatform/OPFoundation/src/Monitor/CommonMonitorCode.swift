//
//  CommonMonitorCode.swift
//  ECOInfra
//
//  Created by justin on 2022/12/14.
//

import Foundation
import ECOProbe

/// FROM: CommonErrorDefine.swift
/// 通用 Monitor ID 定义
/// - 修改请先修改 [统一定义文档](https://bytedance.feishu.cn/sheets/shtcnCCboz4CUWBUtZkdmZV0PLb?table=tblhdeAY8y&view=vewDYgteNU#ve29xQ)

@objcMembers
public final class CommonMonitorCode: OPMonitorCode {

    /// 不合法的参数
    static public let invalid_params = CommonMonitorCode(code: 10000, level: OPMonitorLevelError, message: "invalid_params")
    /// 失败
    static public let fail = CommonMonitorCode(code: 10001, level: OPMonitorLevelError, message: "fail")
    /// 取消
    static public let cancel = CommonMonitorCode(code: 10002, level: OPMonitorLevelWarn, message: "cancel")
    /// 成功
    static public let success = CommonMonitorCode(code: 10003, level: OPMonitorLevelNormal, message: "success")
    /// 网络请求参数加解密失败
    static public let encrypt_decrypt_failed = CommonMonitorCode(code: 10004, level: OPMonitorLevelError, message: "encrypt_decrypt_failed")
    /// 小程序网络trace
    static public let network_rust_trace = CommonMonitorCode(code: 10005, level: OPMonitorLevelNormal, message: "network_rust_trace")

    private init(code: Int, level:  OPMonitorLevel, message: String) {
        super.init(domain: CommonMonitorCode.domain, code: code, level: level, message: message)
    }

    static public let domain = "client.open_platform.common"
}
