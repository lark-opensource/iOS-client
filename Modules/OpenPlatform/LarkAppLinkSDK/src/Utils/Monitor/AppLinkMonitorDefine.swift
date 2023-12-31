//
//  AppLinkMonitorDefine.swift
//  LarkAppLinkSDK
//
//  Created by yinyuan on 2020/5/28.
//

import Foundation
import ECOProbe 

/// OPMonitor 扩展 for AppLink
public extension OPMonitor {

    /// 添加 applink 信息，将会新增 from 和 url 参数
    /// - Parameters:
    ///   - appLink: appLink
    func setAppLink(_ appLink: AppLink?) -> OPMonitor {
        if let appLink = appLink {
            return addCategoryValue("from", appLink.from.rawValue)
                .addCategoryValue("url", appLink.url.applinkEncyptString())
                .addCategoryValue("scheme", appLink.url.scheme)
                .addCategoryValue("host", appLink.url.host)
                .addCategoryValue("path", appLink.url.path)
                .addCategoryValue("appId", appLink.url.queryParameters["appId"])
                .addCategoryValue("applink_trace_id", appLink.traceId)
                .addCategoryValue("op_tracking", appLink.url.queryParameters["op_tracking"]) // 用于追踪 applink 链接
        }
        return self
    }
}

/// Monitor Code 定义
/// - 修改请先修改 [统一定义文档](https://bytedance.feishu.cn/sheets/shtcnCCboz4CUWBUtZkdmZV0PLb?table=tblhdeAY8y&view=vewDYgteNU#ve29xQ)
@objcMembers
public final class AppLinkMonitorCode: OPMonitorCode {

    /// 短链请求超时
    static public let shortLinkRequestTimeout = AppLinkMonitorCode(code: 10_001, level: OPMonitorLevelError, message: "short_link_request_timeout")
    /// 短链请求失败
    static public let shortLinkRequestFail = AppLinkMonitorCode(code: 10_002, level: OPMonitorLevelError, message: "short_link_request_fail")
    /// 版本不支持
    static public let versionNotSupport = AppLinkMonitorCode(code: 10_003, level: OPMonitorLevelError, message: "version_not_support")
    /// 路径不支持
    static public let pathNotSupport = AppLinkMonitorCode(code: 10_004, level: OPMonitorLevelError, message: "path_not_support")
    /// 没有业务接受处理
    static public let noHandler = AppLinkMonitorCode(code: 10_006, level: OPMonitorLevelError, message: "no_handler")
    /// 不合法的 applink
    static public let invalidApplink = AppLinkMonitorCode(code: 10_007, level: OPMonitorLevelWarn, message: "invalid_applink")
    /// 不合法的参数
    static public let invalidParams = AppLinkMonitorCode(code: 10_008, level: OPMonitorLevelError, message: "invalid_params")
    /// rust返回失败
    static public let rustResponseFail = AppLinkMonitorCode(code: 10_009, level: OPMonitorLevelError, message: "rust_response_fail")
    /// applink 降级跳转
    static public let applinkInvalidClick = AppLinkMonitorCode(code: 10_010, level: OPMonitorLevelWarn, message: "applink_invalid_click")
    /// applink 路由
    static public let applinkRoute = AppLinkMonitorCode(code: 10_048, level: OPMonitorLevelNormal, message: "applink_route")
    /// scene来源为空，iPad下不支持
    // swiftlint:disable identifier_name
    static public let from_scene_is_null = AppLinkMonitorCode(code: 10_049, level: OPMonitorLevelError, message: "from_scene_is_null")
    // swiftlint:enable identifier_name

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: AppLinkMonitorCode.domain, code: code, level: level, message: message)
    }

    /// domain
    static public let domain = "client.open_platform.applink"
}
