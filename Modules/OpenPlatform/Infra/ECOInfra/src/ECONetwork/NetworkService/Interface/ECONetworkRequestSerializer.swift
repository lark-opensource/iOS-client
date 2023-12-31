//
//  ECONetworkRequestSerialization.swift
//  NetworkClientSwiftTest
//
//  Created by MJXin on 2021/5/24.
//

import Foundation

public typealias ContentTypeString = String

/// Request 数据被序列化的结果, (ContentTypeString 仅用于兜底, 正确用法是在 RequestConfig 中明确指定 Contentype)
public enum ECONetworkSerializeResult {
    /// 序列化为  QueryItem 类型, 会被拼接在 URL 中
    case urlQueryItems([URLQueryItem])
    /// 序列化为 Data 类型, 会被放在 HttpBody 中 (ContentTypeString 仅用于兜底, Request 没有对应字段时才会被使用)
    case bodyData(Data, ContentTypeString)
    /// 序列化为 URL 类型, 会被用于底层上传的入参 (ContentTypeString 仅用于兜底, Request 没有对应字段时才会被使用)
    case uploadFileURL(URL, ContentTypeString)
}

public protocol ECONetworkRequestSerializer {
    associatedtype Parameters
    
    /// 序列化请求数据
    /// - Parameters:
    ///   - context: 提供发起请求时的上下文信息供内部使用(createTask 时传入的 context)
    ///   - request: 未经序列化的 request, Serializer 根据自身需求使用内部数据
    ///   - params: 请求时同步带入的入参,  描述当前接口的业务信息.
    func serialize(context: ECONetworkServiceContext, request: ECONetworkRequestOrigin, params: Parameters) throws -> ECONetworkSerializeResult
}

