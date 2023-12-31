//
//  ECOCookie+Monitor.swift
//  ECOInfra
//
//  Created by Meng on 2021/2/24.
//

import Foundation
import ECOProbe

final class ECOCookieMonitorCode: OPMonitorCode {
    static let domain = "client.open_platform.common.cookie"

    /// 读写请求事件名
    static let monitorName = "op_common_cookie_sync"

    // swiftlint:disable identifier_name
    /// [tt.request相关请求] 读取cookie结果
    static let read_app_cookie = ECOCookieMonitorCode(code: 10000, message: "read_app_cookie")

    /// [tt.request相关请求] 写入cookie结果
    static let write_app_cookie = ECOCookieMonitorCode(code: 10001, message: "write_app_cookie")

    /// cookie 双读模式，读取到了 global 但是 gadget 没读到的 Cookie
    /// 比如 global [cookie1, cookie2],gadget [cookie1, cookie3], 此时需要上报 cookie2
    static let read_all_cookie_miss =
        ECOCookieMonitorCode(code: 10002, level: OPMonitorLevelError, message: "read_all_cookie_miss")

    /// iOS 保存 response cookie 失败
    static let save_response_cookie_failed =
        ECOCookieMonitorCode(code: 10003, level: OPMonitorLevelError, message: "save_response_cookie_failed")

    /// iOS cookie domain mask 转换失败
    static let domain_convert_failed =
        ECOCookieMonitorCode(code: 10004, level: OPMonitorLevelError, message: "domain_convert_failed")

    /// 同步 cookie 到小程序 webview 容器
    static let sync_webview_cookies = ECOCookieMonitorCode(code: 10005, message: "sync_webview_cookies")

    /// 创建隔离的 website datastore
    static let create_isolate_website_datastore = ECOCookieMonitorCode(code: 10006, message: "create_isolate_website_datastore")
    // swiftlint:enable identifier_name

    private init(code: Int, level: OPMonitorLevel = OPMonitorLevelNormal, message: String) {
        super.init(domain: Self.domain, code: code, level: level, message: message)
    }
}
