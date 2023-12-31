//
//  OPWebErrorDefine.swift
//  Timor
//
//  Created by lixiaorui on 2020/5/26.
//

import Foundation
import LarkOPInterface

/// H5应用 Monitor ID 定义
/// - 修改请先修改 [统一定义文档](https://bytedance.feishu.cn/sheets/shtcnCCboz4CUWBUtZkdmZV0PLb?table=tblhdeAY8y&view=vewDYgteNU#ve29xQ)
@objcMembers
public final class OWMonitorCodeWebview: OPMonitorCode {

    /// webview执行js错误
    static public let evaluate_js_error = OWMonitorCodeWebview(code: 10000, level: OPMonitorLevelError, message: "evaluate_js_error")

    /// webview加载失败
    static public let provisional_navigation_error = OWMonitorCodeWebview(code: 10001, level: OPMonitorLevelError, message: "provisional_navigation_error")

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: OWMonitorCodeWebview.domain, code: code, level: level, message: message)
    }

    static public let domain = "client.open_platform.web.webview"
}

@objcMembers
public final class OWMonitorCodeApi: OPMonitorCode {

    /// H5 App API调用成功
    static public let success = OWMonitorCodeApi(code: 10000, level: OPMonitorLevelNormal, message: "success")

    /// api调用失败
    static public let fail = OWMonitorCodeApi(code: 10001, level: OPMonitorLevelError, message: "fail")

    /// api调用取消
    static public let cancel = OWMonitorCodeApi(code: 10002, level: OPMonitorLevelWarn, message: "cancel")

    /// 参数错误
    static public let param_error = OWMonitorCodeApi(code: 10005, level: OPMonitorLevelError, message: "param_error")

    /// 请求权限非法
    static public let invalid_scope = OWMonitorCodeApi(code: 10006, level: OPMonitorLevelError, message: "invalid_scope")

    /// SDK内部未实现/未注册
    static public let no_handler = OWMonitorCodeApi(code: 10007, level: OPMonitorLevelError, message: "no_handler")

    /// 宿主未实现
    static public let no_host_handler = OWMonitorCodeApi(code: 10008, level: OPMonitorLevelError, message: "no_host_handler")

    /// 无权限管理器
    static public let no_authorization = OWMonitorCodeApi(code: 10009, level: OPMonitorLevelError, message: "no_authorization")

    /// 用户未授权
    static public let no_user_permission = OWMonitorCodeApi(code: 10010, level: OPMonitorLevelError, message: "no_user_permission")

    /// 系统未授权
    static public let no_system_permisson = OWMonitorCodeApi(code: 10011, level: OPMonitorLevelError, message: "no_system_permisson")

    /// 开放平台SDK未授权
    static public let no_platform_permisson = OWMonitorCodeApi(code: 10012, level: OPMonitorLevelError, message: "no_platform_permisson")

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: OWMonitorCodeApi.domain, code: code, level: level, message: message)
    }

    static public let domain = "client.open_platform.web.api"
}

@objcMembers
public final class OWMonitorCodeApiAuth: OPMonitorCode {

    /// 请求权限成功
    static public let request_success = OWMonitorCodeApiAuth(code: 10000, level: OPMonitorLevelNormal, message: "request_success")

    /// 请求权限网络错误（网络库内部错误）
    static public let request_network_error = OWMonitorCodeApiAuth(code: 10001, level: OPMonitorLevelError, message: "request_network_error")

    /// 请求权限接口返回，但code非0
    static public let request_result_biz_fail = OWMonitorCodeApiAuth(code: 10002, level: OPMonitorLevelError, message: "request_result_biz_fail")

    /// 请求权限接口返回code=0，但data数据错误
    static public let request_result_data_invalid = OWMonitorCodeApiAuth(code: 10003, level: OPMonitorLevelError, message: "request_result_data_invalid")

    /// 权限数据解密错误
    static public let request_result_decrypt_error = OWMonitorCodeApiAuth(code: 10004, level: OPMonitorLevelError, message: "request_result_decrypt_error")

    /// 内部错误
    static public let internal_error = OWMonitorCodeApiAuth(code: 10005, level: OPMonitorLevelError, message: "internal_error")

    /// 需要走权限体系，但没有session
    static public let auth_has_no_session = OWMonitorCodeApiAuth(code: 10006, level: OPMonitorLevelError, message: "auth_has_no_session")

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: OWMonitorCodeApiAuth.domain, code: code, level: level, message: message)
    }

    static public let domain = "client.open_platform.web.api_auth"
}
