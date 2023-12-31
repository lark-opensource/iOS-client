//
//  ECONetworkMonitorDefine.swift
//  ECOInfra
//
//  Created by 刘焱龙 on 2023/5/4.
//

import Foundation

struct ECONetworkLogKey {
    static let startRequest = "start_request"
    static let startRequestEdit = "start_request_edit"
    static let startRequestError = "start_request_error"
    static let sendRequest = "send_request"
    static let getResponse = "get_response"
    static let getResponseEdit = "get_response_edit"
    static let endResponse = "end_response"
}

struct ECONetworkMonitorKey {
    static let requestSource = "request_source"

    static let domain = "domain"
    static let path = "path"
    static let method = "method"

    static let requestId = "request_id"
    static let netStatus = "net_status"
    static let requestType = "request_type"

    static let httpCode = "http_code"
    static let requestBodyLength = "request_body_length"
    static let responseBodyLength = "response_body_length"
    static let resultType = "result_type"

    static let appId = "app_id"
    static let appType = "app_type"

    static let larkErrorCode = "lark_error_code"
    static let larkErrorStatus = "lark_error_status"

    static let source = "source"
    static let logId = "logId"
}
