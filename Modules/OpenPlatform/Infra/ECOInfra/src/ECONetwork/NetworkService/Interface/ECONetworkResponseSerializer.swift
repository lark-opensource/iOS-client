//
//  ECONetworkResponseSerialization.swift
//  NetworkClientSwiftTest
//
//  Created by MJXin on 2021/5/24.
//

import Foundation

/// Response 序列化器的协议
/// 返回类型为泛型由实现类自己决定, 在 RequestConfig 中, 会要求与 ResultType 相同
public protocol ECONetworkResponseSerializer {
    associatedtype SerializedObject
    
    /// 将 原始的 Response 序列化为指定数据类型
    /// - Parameters:
    ///   - context: 提供发起请求时的上下文信息供内部使用(createTask 时传入的 context)
    ///   - response: 原始,待序列化的 Response
    func serialize(context: ECONetworkServiceContext, response: ECONetworkResponseOrigin) throws -> SerializedObject?
}

