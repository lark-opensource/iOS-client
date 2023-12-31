//
//  OpenPluginManagerProtocol.swift
//  LarkOpenApis
//
//  Created by lixiaorui on 2021/1/25.
//

import Foundation

public protocol OpenPluginManagerProtocol: AnyObject {

    /// 强类型异步调度具体api，派发给apiHandler实现逻辑
    /// - Parameters:
    ///   - apiName: 事件名称
    ///   - params: 外部透传参数对应的model
    ///   - canUseInternalAPI: 是否能使用内部(未开放给JS的)API，从JS直接调用的地方需要传false
    ///   - context: apiHandler内部需要的上下文
    ///   - callback: api回调
    func asyncCall<Param>(
        apiName: String,
        params: Param,
        canUseInternalAPI: Bool,
        context: OpenAPIContext,
        callback: @escaping OpenAPISimpleCallback
    ) where Param: OpenAPIBaseParams

    /// 强类型同步调度具体api，派发给apiHandler实现逻辑
    /// - Parameters:
    ///   - apiName: 事件名称
    ///   - params: 外部透传参数对应的model
    ///   - canUseInternalAPI: 是否能使用内部(未开放给JS的)API，从JS直接调用的地方需要传false
    ///   - context: apiHandler内部需要的上下文
    func syncCall<Param>(
        apiName: String,
        params: Param,
        canUseInternalAPI: Bool,
        context: OpenAPIContext
    ) -> OpenAPISimpleResponse where Param: OpenAPIBaseParams

    /// 弱类型异步调度具体api，派发给apiHandler实现逻辑
    /// - Parameters:
    ///   - apiName: 事件名称
    ///   - params: 外部透传参数
    ///   - canUseInternalAPI: 是否能使用内部(未开放给JS的)API，从JS直接调用的地方需要传false
    ///   - context: apiHandler内部需要的上下文
    ///   - callback: api回调
    func asyncCall(
        apiName: String,
        params: [AnyHashable: Any],
        canUseInternalAPI: Bool,
        context: OpenAPIContext,
        callback: @escaping OpenAPISimpleCallback
    )

    /// 弱类型同步调度具体api，派发给apiHandler实现逻辑
    /// - Parameters:
    ///   - apiName: 事件名称
    ///   - params: 外部透传参数
    ///   - canUseInternalAPI: 是否能使用内部(未开放给JS的)API，从JS直接调用的地方需要传false
    ///   - context: apiHandler内部需要的上下文
    func syncCall(
        apiName: String,
        params: [AnyHashable: Any],
        canUseInternalAPI: Bool,
        context: OpenAPIContext
    ) -> OpenAPISimpleResponse

    /// 派发多播事件
    /// - Parameters:
    ///   - eventName: 事件名称
    ///   - params: 外部透传参数对应的model
    ///   - context: apiHandler内部需要的上下文
    ///   - callback: api回调
    func postEvent<Param, Result>(
        eventName: String,
        params: Param,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<Result>) -> Void
    ) where Param: OpenAPIBaseParams, Result: OpenAPIBaseResult
}
