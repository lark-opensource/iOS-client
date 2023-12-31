//
//  WPRequestTraceMiddleware.swift
//  LarkWorkplace
//
//  Created by Jiayun Huang on 2022/12/6.
//

import Foundation
import ECOInfra
import LarkOPInterface
import LKCommonsLogging

struct WPRequestTraceMiddleware: ECONetworkMiddleware {
    private static let logger = Logger.log(WPRequestTraceMiddleware.self)

    init() {}

    func processRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<ECONetworkRequest, Error> {
        // 生成 logId
        task.trace.genRequestID(OP_REQUEST_ENGINE_SOURCE)
        // 不因为 trace 阻塞后续请求
        guard let logId = task.trace.getRequestID() else {
            WPRequestTraceMiddleware.logger.error("requestID is nil")
            assertionFailure("requestID is nil")
            return .success(request)
        }

        var networkRequest = request
        networkRequest.setHeaderField(key: OP_REQUEST_TRACE_HEADER, value: task.trace.traceId)
        networkRequest.setHeaderField(key: OP_REQUEST_LOGID_HEADER, value: logId)

        // 不因为 context 类型阻塞后续请求
        guard let context = task.context as? WPNetworkContext else {
            WPRequestTraceMiddleware.logger.error("processRequest fail, context type error")
            assertionFailure("context type error")
            return .success(networkRequest)
        }
        context.setLogID(logId)
        return .success(networkRequest)
    }
}
