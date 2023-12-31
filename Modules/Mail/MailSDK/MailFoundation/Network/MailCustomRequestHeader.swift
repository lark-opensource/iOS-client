//
//  CustomHeader.swift
//  DocsSDK
//
//  Created by huahuahu on 2018/11/25.
//

import Foundation

// 自定义请求头
enum MailCustomRequestHeader: String {
    case requestID = "request-id"
    case xRequestID = "x-request-id"
    case accessCredentials = "access-control-allow-credentials"
    case accessMethods = "access-control-allow-methods"
    case accessOrigin = "access-control-allow-origin"
    case deviceId = "mail-device-id"
}
