//
//  OPNetworkMiddlewares.swift
//  EEMicroAppSDK
//
//  Created by MJXin on 2021/6/16.
//

import Foundation
import LarkContainer
import LKCommonsLogging

public final class OPRequestTraceMiddleware: ECONetworkMiddleware {
    private static let logger = Logger.oplog(OPRequestTraceMiddleware.self, category: "EEMicroAppSDK")
    
    public init() {}
    
    public func processRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<ECONetworkRequest, Error> {
        // 生成 requestID
        task.trace.genRequestID(OP_REQUEST_ENGINE_SOURCE)
        // 不因为 trace 阻塞后续请求
        guard let requestID = task.trace.getRequestID() else {
            Self.logger.error("requestID is nil")
            assertionFailure("requestID is nil")
            return .success(request)
        }
        var request = request
        request.setHeaderField(key: OP_REQUEST_TRACE_HEADER, value: task.trace.traceId)
        request.setHeaderField(key: OP_REQUEST_ID_HEADER, value: requestID)
        request.setHeaderField(key: OP_REQUEST_LOGID_HEADER, value: requestID)
        return .success(request)
    }
}

/// OpenPlatform 网络请求通用参数
public final class OPRequestCommonParamsMiddleware: ECONetworkMiddleware {
    
    @Provider private var dependency: ECONetworkDependency // Global

    private let shouldAddUA: Bool
    
    public init(shouldAddUA: Bool = true) {
        self.shouldAddUA = shouldAddUA
    }

    public func processRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<ECONetworkRequest, Error> {
        var request = request
        // 通用 body
        request.mergingBodyFields(with: [
            "app_version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "",
            "platform": "ios"
        ])

        // 通用 header
        request.setHeaderField(key: "called_from", value: "miniapp")

        if shouldAddUA {
            request.setHeaderField(key: "User-Agent", value: dependency.getUserAgentString())
        }

        if !request.headerFields.keys.contains(where: { $0.lowercased() == "content-type" }) {
            request.setHeaderField(key: "content-type", value: "application/json")
        }
        return .success(request)
    }
}


/// OpenPlatform 日志中间件
public final class OPRequestLogMiddleware: ECONetworkMiddleware {
    private static let logger = Logger.oplog(OPRequestLogMiddleware.self, category: "EEMicroAppSDK")
    private let RequestTag = "Request"
    
    public init() {}
    
    public func willStartRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<Void, Error> {
        do {
            let url = try request.getURL()
            Self.logger.info("beginRequest url=\(String(describing: NSString.safeURL(url))), trace=\(String(describing: task.trace.traceId))", tag: RequestTag)
        } catch let error {
            // url 拼接失败,查一下是不是 domain或 path 写错为空
            // 常见于, domain 类型定义要 String? 写成了 String. path 没有带 / 等
            // 可以搜 "get url fail scheme" 看打印信息
            Self.logger.error("get url fail with error: \(error)", tag: RequestTag)
            assertionFailure("get url fail with error: \(error)")
        }
        // 日志 middleware 不打断流程
        return .success(())
    }
    
    public func didCompleteRequest<ResultType>(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest,
        response: ECONetworkResponse<ResultType>
    ) -> Result<Void, Error> {
        do {
            let url = try request.getURL()
            Self.logger.info(
                "endRequest url=\(String(describing: NSString.safeURL(url))), trace=\(String(describing: task.trace.traceId)), responseCode=\(response.statusCode)",
                tag: RequestTag
            )
        } catch let error {
            Self.logger.error("get url fail with error: \(error)", tag: RequestTag)
            assertionFailure("get url fail with error: \(error)")
        }
        // 日志 middleware 不打断流程
        return .success(())
    }
    
    public func requestException<ResultType>(
        task: ECONetworkServiceTaskProtocol,
        error: Error,
        request: ECONetworkRequest?,
        response: ECONetworkResponse<ResultType>?
    ) {
        do {
            let url = try request?.getURL()
            Self.logger.info(
                "endRequest url=\(String(describing: NSString.safeURL(url))), trace=\(String(describing: task.trace.traceId)), error=\(error)",
                tag: RequestTag
            )
        } catch let error {
            Self.logger.error("get url fail with error: \(error)", tag: RequestTag)
            assertionFailure("get url fail with error: \(error)")
        }
    }
}
