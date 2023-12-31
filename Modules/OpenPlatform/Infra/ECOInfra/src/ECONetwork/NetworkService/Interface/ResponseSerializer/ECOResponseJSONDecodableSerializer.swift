//
//  ECOResponseJSONDecodableSerializer.swift
//  ECOInfra
//
//  Created by MJXin on 2021/6/4.
//

import Foundation
import SwiftyJSON

/// 将 Data 数据直接序列化为指定的数据结构:(需要 ResultType 是 Decodable 的)
public final class ECOResponseJSONDecodableSerializer<T: Decodable>: ECONetworkResponseSerializer {
    private let resultType: T.Type
    
    /// 初始化需要指定类型, 以后续泛型使用
    public init(type: T.Type) { resultType = type }
    
    /// 将 BodyData 序列化为指定数据类型
    /// - Parameters:
    ///   - context: 提供发起请求时的上下文信息供内部使用(createTask 时传入的 context)
    ///   - response: 原始,待序列化的 Response
    /// - Throws: 序列化过程报错
    /// - Returns: 指定的数据结构
    public func serialize(context: ECONetworkServiceContext, response: ECONetworkResponseOrigin) throws -> T? {
        guard let data = response.bodyData else { return nil }
        // 另有个 ECOResponseJSONSerializer，本身 JSON 也是实现 Decodable 的，这里兼容一下 JSON
        if resultType is JSON.Type {
            return try JSON(data: data) as? T
        }
        return try JSONDecoder().decode(resultType, from: data)
    }
}
