//
//  ECONetworkTaskDescriptor.swift
//  NetworkClientSwiftTest
//
//  Created by MJXin on 2021/5/24.
//

import Foundation

/// ECONetworkService 对外提供描述本次请求的数据结构,
/// 同时也是本次请求的上下文对象
/// 外部需要使用此对象调用 NetworkService 实现网络请求
public final class ECONetworkServiceTask<ResultType>: ECONetworkServiceTaskProtocol, ECONetworkEventHandler {
    public let identifier: String
    public let type: ECONetworkTaskType
    /// 调用 NetworkService 时所携带的上下文, 内部不会修改, 而是在对外的接口中重新提供出去
    public let context: ECONetworkServiceContext
    /// 从上一级 Trace 中派生
    public let trace: OPTrace
    /// 任务的进度监听, 包含发送和接收进度, 可以通过 service 注册为监听者
    public let progress: ECONetworkProgress
    /// 请求任务 Pipeline
    public let requestPipeline: ECONetworkServicePipeline<ResultType>
    
    /// 请求中产生的指标信息
    public internal(set) var metrics: ECONetworkMetrics?
    public internal(set) var request: ECONetworkRequest
    public internal(set) var response: ECONetworkResponse<ResultType>?

    private var appContext: ECONetworkServiceAppContext? {
        return context as? ECONetworkServiceAppContext
    }
    
    // ❗勿对模块外暴露初始化接口, 外部只读, 只允许内部操作
    init<Config: ECONetworkRequestConfig>(
        config: Config.Type,
        context: ECONetworkServiceContext,
        type: ECONetworkTaskType,
        pipeline: ECONetworkServicePipeline<ResultType>,
        callbackQueue: DispatchQueue
    ) {
        self.identifier = ECOIdentifier.createIdentifier(key: "ECONetworkServiceTask")
        self.trace = context.getTrace().subTrace()
        self.request = Self.createRequest(from: config, trace: self.trace)
        self.type = type
        self.context = context
        self.requestPipeline = pipeline
        self.progress = ECONetworkProgress(callbackQueue: callbackQueue)

        updateTrace()
    }

    private func updateTrace() {
        trace.genRequestID(getSourceString())
    }
    
    public func getTrace() -> OPTrace { trace }

    public func getAppId() -> String? {
        return appContext?.getAppId()
    }

    public func getAppType() -> String? {
        return appContext?.getAppType()
    }

    public func getSource() -> ECONetworkRequestSourceWapper? {
        return context.getSource?()
    }

    public func getSourceString() -> String {
        return (getSource() ?? ECONetworkRequestSourceWapper(source: .other)).sourceString
    }

    /// 从静态配置中创建一个初始的 Request
    /// 这个 Request 不是最终用于网络请求的 Request. 里面是未经序列化的裸数据, 会在流程中被各种加工. 直到请求前才转为下层的 request
    /// - Parameter config: 请求的配置
    private static func createRequest<Config: ECONetworkRequestConfig>(
        from config: Config.Type,
        trace: OPTrace
    ) -> ECONetworkRequest {
        return ECONetworkRequest(
            scheme: config.scheme,
            domain: config.domain,
            path: config.path,
            method: config.method,
            port: config.port,
            headerFields: config.initialHeaders,
            setting: config.setting,
            trace: trace
        )
    }
}
