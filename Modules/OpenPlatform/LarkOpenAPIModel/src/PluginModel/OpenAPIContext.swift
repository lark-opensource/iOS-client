//
//  OpenAPIContext.swift
//  LarkOpenApis
//
//  Created by lixiaorui on 2021/2/3.
//

import Foundation
import ECOProbe
import ECOInfra

// 一次API调用链路生成一个OpenAPIContext
@objcMembers
open class OpenAPIContext: NSObject {
    public let apiTrace: OPTrace

    private weak var forwardDispatcher: OpenPluginManagerProtocol?

    public var additionalInfo: [AnyHashable: Any]

    public let isLazyInvoke: Bool
    public let lazyInvokeElapsedDuration: Int64?

    convenience public init(
        trace: OPTrace,
        dispatcher: OpenPluginManagerProtocol? = nil,
        additionalInfo: [AnyHashable: Any] = [:]
    ) {
        self.init(
            trace: trace,
            dispatcher: dispatcher,
            additionalInfo: additionalInfo,
            isLazyInvoke: false,
            lazyInvokeElapsedDuration: nil
        )
    }

    public init(
        trace: OPTrace,
        dispatcher: OpenPluginManagerProtocol? = nil,
        additionalInfo: [AnyHashable: Any] = [:],
        isLazyInvoke: Bool,
        lazyInvokeElapsedDuration: Int64?
    ) {
        self.apiTrace = trace
        self.forwardDispatcher = dispatcher
        self.additionalInfo = additionalInfo
        self.isLazyInvoke = isLazyInvoke
        self.lazyInvokeElapsedDuration = lazyInvokeElapsedDuration
    }
    
    public func getTrace() -> OPTrace {
        return apiTrace
    }

    // 支持强类型调用异步转发
    public func asyncCall<Param>(
        apiName: String,
        params: Param,
        context: OpenAPIContext,
        callback: @escaping OpenAPISimpleCallback
    ) where Param: OpenAPIBaseParams {
        guard let dispatcher = forwardDispatcher else {
            apiTrace.error("can not find api dispatcher in context for \(apiName)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setMonitorMessage("can not find api dispatcher in context for \(apiName)")
            callback(.failure(error: error))
            return
        }
        dispatcher.asyncCall(
            apiName: apiName,
            params: params,
            canUseInternalAPI: true,
            context: context,
            callback: callback
        )
    }

    // 支持弱类型调用异步转发
    public func asyncCall(
        apiName: String,
        params: [AnyHashable: Any],
        context: OpenAPIContext,
        callback: @escaping OpenAPISimpleCallback
    ) {
        guard let dispatcher = forwardDispatcher else {
            apiTrace.error("can not find api dispatcher in context for \(apiName)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setMonitorMessage("can not find api dispatcher in context for \(apiName)")
            callback(.failure(error: error))
            return
        }
        dispatcher.asyncCall(
            apiName: apiName,
            params: params,
            canUseInternalAPI: true,
            context: context,
            callback: callback
        )
    }

    // 支持强类型调用同步转发
    public func syncCall<Param>(
        apiName: String,
        params: Param,
        context: OpenAPIContext
    ) -> OpenAPISimpleResponse where Param: OpenAPIBaseParams {
        guard let dispatcher = forwardDispatcher else {
            apiTrace.error("can not find api dispatcher in context for \(apiName)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setMonitorMessage("can not find api dispatcher in context for \(apiName)")
            return .failure(error: error)
        }
        return dispatcher.syncCall(
            apiName: apiName,
            params: params,
            canUseInternalAPI: true,
            context: context
        )
    }

    // 支持弱类型调用同步转发
    public func syncCall(
        apiName: String,
        params: [AnyHashable: Any],
        context: OpenAPIContext
    ) -> OpenAPISimpleResponse {
        guard let dispatcher = forwardDispatcher else {
            apiTrace.error("can not find api dispatcher in context for \(apiName)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setMonitorMessage("can not find api dispatcher in context for \(apiName)")
            return .failure(error: error)
        }
        return dispatcher.syncCall(
            apiName: apiName,
            params: params,
            canUseInternalAPI: true,
            context: context
        )
    }

    // 多播消息发送
    public func postEvent<Param, Result>(
        eventName: String,
        params: Param,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<Result>) -> Void
    ) where Param: OpenAPIBaseParams, Result: OpenAPIBaseResult {
        guard let dispatcher = forwardDispatcher else {
            apiTrace.error("can not find api dispatcher in context for \(eventName)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setMonitorMessage("can not find api dispatcher in context for \(eventName)")
            callback(.failure(error: error))
            return
        }
        dispatcher.postEvent(eventName: eventName, params: params, context: context, callback: callback)
    }
}
