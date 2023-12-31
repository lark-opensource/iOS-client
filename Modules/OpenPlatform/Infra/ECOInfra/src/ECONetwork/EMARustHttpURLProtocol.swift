//
//  EMARustHttpURLProtocol.swift
//  EEMicroAppSDK
//
//  Created by changrong on 2020/6/21.
//

import Foundation
import LarkRustHTTP
import LKCommonsLogging
import HTTProtocol
import ECOProbe

/// 在开启swift二进制的情况下，继承自其他模块的Class: EMARustHttpURLProtocol
/// 无法直接被OC代码调用，这里加了一层包装，绕开这个限制
@objc final public class SwiftToOCBridge: NSObject {
    @objc public class var _EMARustHttpURLProtocol: AnyClass {
        EMARustHttpURLProtocol.self
    }

    @objc public class var monitorRustHttpURLProtocol: AnyClass {
        ECOMonitorRustHttpURLProtocol.self
    }
}

/// EMA 私有化的 RustHTTPURLProtocol，目的为重写部分开放能力
public class EMARustHttpURLProtocol: RustHttpURLProtocol {
    static let logger = Logger.oplog(EMARustHttpURLProtocol.self, category: "EMARustHttpURLProtocol")
    // MARK: Request
     public override func willStartRequestServer(request: FetchRequest?) {
        super.willStartRequestServer(request: request)
        guard let rustRequest = request else {
            Self.logger.error("request is nil!", tag: "network")
            assertionFailure("request is nil")
            return
        }
        let (requestID, trace) = getRequestId(rustRequest: rustRequest)
        OPMonitor(name: kEventName_mp_network_rust_trace, code: ECOCommonMonitorCode.network_rust_trace)
            .tracing(trace)
            .addCategoryValue("request_id", requestID)
            .addCategoryValue("url", NSString.safeURLString(rustRequest.url))
            .addCategoryValue("rust_task_id", rustRequest.requestID)
            .flush()
    }

    fileprivate func getRequestId(rustRequest: FetchRequest) -> (requestID: String?, trace: OPTrace?) {
        var trace: OPTrace?
        var requestID: String?
        for header in rustRequest.headers {
            if header.hasName && header.name.lowercased() == OP_REQUEST_TRACE_HEADER.lowercased() {
                trace = OPTrace(traceId: header.value)
            }
            if header.hasName && header.name.lowercased() == OP_REQUEST_ID_HEADER.lowercased() {
                requestID = header.value
            }
        }
        return (requestID, trace)
    }
}

/*
 在 URLProtocol 进行埋点:
 1. 没法处理重定向的场景，重定向会创建多个 URLProtocol 实例，会导致埋多次点
 2. 复用缓存的场景和正常请求区别就在于没有使用网络，不影响埋点
 */
public class ECOMonitorRustHttpURLProtocol: EMARustHttpURLProtocol {
    private var monitor: OPMonitor?

    private var requestType: String {
        var type = "request"
        if task as? URLSessionDownloadTask != nil {
            type = "download"
        } else if task as? URLSessionUploadTask != nil {
            type = "upload"
        }
        return type
    }

    public override func willStartRequestServer(request: FetchRequest?) {
        super.willStartRequestServer(request: request)
        guard let rustRequest = request else {
            return
        }
        let (requestId, trace) = getRequestId(rustRequest: rustRequest)
        let url = URL(string: rustRequest.url)
        monitor = OPMonitor(kEventName_op_legacy_internal_request_result)
            .tracing(trace)
            .addCategoryValue(ECONetworkMonitorKey.requestSource, "ECOMonitorRustHttpURLProtocol")
            .addCategoryValue(ECONetworkMonitorKey.domain, url?.host ?? "")
            .addCategoryValue(ECONetworkMonitorKey.path, url?.path ?? "")
            .addCategoryValue(ECONetworkMonitorKey.requestId, requestId)
            .addCategoryValue(ECONetworkMonitorKey.netStatus, OPNetStatusHelper.netStatusName())
            .addCategoryValue(ECONetworkMonitorKey.requestType, requestType)
            .addCategoryValue(ECONetworkMonitorKey.method, self.request.httpMethod)
            .timing()
    }

    public override func stopLoading() {
        super.stopLoading()
        let error = task?.error
        monitor?
            .addCategoryValue(ECONetworkMonitorKey.resultType, (error == nil) ? "success" : "fail")
            .addCategoryValue(ECONetworkMonitorKey.httpCode, metrics.response?.statusCode ?? 0)
            .addCategoryValue(ECONetworkMonitorKey.responseBodyLength, task?.countOfBytesExpectedToReceive ?? 0)
            .addCategoryValue(ECONetworkMonitorKey.requestBodyLength, task?.countOfBytesExpectedToSend ?? 0)
            .setError(error)
            .timing()
            .flush()
    }
}
