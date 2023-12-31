//
//  WPNetworkMonitorMiddleware.swift
//  LarkWorkplace
//
//  Created by Jiayun Huang on 2022/12/29.
//

import Foundation
import ECOInfra
import LarkOPInterface

final class WPNetworkMonitorMiddleware: ECONetworkMiddleware {
    private var startTime = CACurrentMediaTime()

    private let resultMonitor = WPMonitor()

    func willStartRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<Void, Error> {
        startTime = CACurrentMediaTime()
        resultMonitor.timing()

        guard let context = task.context as? WPNetworkContext,
              let url = try? request.getURL() else {
            // 埋点 middleware 不打断流程
            return .success(())
        }
        WPMonitor().setCode(WPMCode.wp_request_start)
            .setTrace(task.context.getTrace())
            .setNetworkStatus()
            .setInfo([
                "log_id": context.logId ?? "",
                "url": NSString.safeURL(url) ?? "",
                "url_host": NSString.safeURLString(request.domain) ?? "",
                "url_path": NSString.safeURLString(request.path) ?? "",
            ])
            .flush()
        return .success(())
    }

    func didCompleteRequest<ResultType>(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest,
        response: ECONetworkResponse<ResultType>
    ) -> Result<Void, Error> {
        guard let context = task.context as? WPNetworkContext,
              let url = try? request.getURL() else {
            // 埋点 middleware 不打断流程
            return .success(())
        }

        let requestInfo: [String: String] = [
            "log_id": context.logId ?? "",
            "url_host": NSString.safeURLString(request.domain) ?? "",
            "url_path": NSString.safeURLString(request.path) ?? "",
            "url": NSString.safeURL(url) ?? "",
            "http_code": "\(response.statusCode)",
            "data_size": "\(response.bodyData?.count ?? -1)"
        ]

        resultMonitor.timing()
            .setCode(WPMCode.wp_request_success)
            .setTrace(task.context.getTrace())
            .setNetworkStatus()
            .setInfo(requestInfo)
            .flush()
        return .success(())
    }

    func requestException<ResultType>(
        task: ECONetworkServiceTaskProtocol,
        error: Error,
        request: ECONetworkRequest?,
        response: ECONetworkResponse<ResultType>?
    ) {
        guard let context = task.context as? WPNetworkContext,
              let url = try? request?.getURL() else {
            return
        }

        let nsError = error as NSError
        var errorMessage = nsError.localizedDescription
        var errorType: WPNetworkErrorType = .unknown
        var errorCode = nsError.code
        /// httpCode 默认值 -1
        var httpCode = -1
        /// rustCode 通过 LarkRustHTTP 透传，不设置默认值，如果没有就不埋点
        var rustStatus: Int?
        if let networkError = error as? ECONetworkError {
            let errorInfo = WPNetworkErrorInfo(error: networkError)
            errorMessage = errorInfo.errorMessage
            errorType = errorInfo.errorType
            rustStatus = errorInfo.rustStatus
            errorCode = errorInfo.errorCode

            if let httpStatusCode = errorInfo.httpCode {
                httpCode = httpStatusCode
            }
        }
        var requestInfo: [String: String] = [
            "log_id": context.logId ?? "",
            "url_host": NSString.safeURLString(request?.domain) ?? "",
            "url_path": NSString.safeURLString(request?.path) ?? "",
            "url": NSString.safeURL(url) ?? "",
            "http_code": "\(httpCode)",
            "error_message": errorMessage,
            "error_type": "\(errorType.rawValue)",
            "error_code": "\(errorCode)"
        ]
        if let rustStatusCode = rustStatus {
            requestInfo["rust_status"] = "\(rustStatusCode)"
        }
        resultMonitor.timing()
            .setCode(WPMCode.wp_request_fail)
            .setTrace(task.context.getTrace())
            .setNetworkStatus()
            .setInfo(requestInfo)
            .flush()
    }
}
