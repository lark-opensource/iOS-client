//
//  ECORequestQueryItemSerializer.swift
//  ECOInfra
//
//  Created by MJXin on 2021/6/4.
//

import Foundation

public final class ECORequestQueryItemSerializer: ECONetworkRequestSerializer {
    
    public init() {}

    /// 将入参序列化为 QueryItem, 最终将被拼接到 URL 上
    /// 使用于 GET
    /// - Parameters:
    ///   - context: 提供发起请求时的上下文信息供内部使用(createTask 时传入的 context)
    ///   - request: 未经序列化的 request, Serializer 根据自身需求使用内部数据
    ///   - params: 请求时同步带入的入参,  描述当前接口的业务信息.
    public func serialize(context: ECONetworkServiceContext, request: ECONetworkRequestOrigin, params: [String: String]?) throws -> ECONetworkSerializeResult {
        guard let params = params, !params.isEmpty else {
            return .urlQueryItems([])
        }
        return .urlQueryItems(params.map{ URLQueryItem(name: $0.key, value: $0.value) })
    }
}
