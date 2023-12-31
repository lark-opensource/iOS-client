//
//  LoginReportRequest.swift
//  LarkMeegoPush
//
//  Created by ByteDance on 2022/7/20.
//

import Foundation
import LarkMeegoNetClient

/// 设备及登录状态上报
/// https://bytedance.feishu.cn/docx/doxcnuZ9QS6rflXJONAguYkmmse

struct LoginReportRequest: Request {
    typealias ResponseType = Response<EmptyDataResponse>

    let method: RequestMethod = .post
    let endpoint: String = "/bff/v1/notification/login_report"
    let catchError: Bool

    let loginStatus: Bool

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        params["login_status"] = loginStatus ? 1 : 0
        return params
    }
}
