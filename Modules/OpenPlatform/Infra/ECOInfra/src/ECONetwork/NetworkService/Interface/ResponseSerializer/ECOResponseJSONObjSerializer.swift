//
//  ECOResponseJSONObjSerializer.swift
//  ECOInfra
//
//  Created by MJXin on 2021/10/22.
//

import Foundation

/// 将 Data 数据反序列化为 Result 类型
public final class ECOResponseJSONObjSerializer<Result>: ECONetworkResponseSerializer {
    private let options: JSONSerialization.ReadingOptions
    
    /// 初始化需要指定类型, 以后续泛型使用
    public init(options: JSONSerialization.ReadingOptions = []) {
        self.options = options
    }
    
    /// 将 BodyData 序列化为指定数据类型
    /// - Parameters:
    ///   - context: 提供发起请求时的上下文信息供内部使用(createTask 时传入的 context)
    ///   - response: 原始,待序列化的 Response
    /// - Throws: 序列化过程报错
    /// - Returns: 指定的数据结构
    public func serialize(context: ECONetworkServiceContext, response: ECONetworkResponseOrigin) throws -> Result? {
        guard let data = response.bodyData else { return nil }
        let serializedObj = try JSONSerialization.jsonObject(with: data, options: options)
        guard let resultObj = serializedObj as? Result else {
            throw ECONetworkError.responseTypeError(detail: "Serialize error: expect result type: \(Result.self), serialized obj type: \(String(describing: serializedObj.self))")
        }
        return resultObj
    }
}
