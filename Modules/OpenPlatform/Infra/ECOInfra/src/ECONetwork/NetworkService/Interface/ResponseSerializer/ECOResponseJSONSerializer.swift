//
//  ECOResponseJSONSerializer.swift
//  ECOInfra
//
//  Created by MJXin on 2021/6/4.
//

import Foundation
import SwiftyJSON

/// 将 Data 反序列化为 JSON 的序列化器
public final class ECOResponseJSONSerializer: ECONetworkResponseSerializer {
    
    public init() {}
    
    /// 将 BodyData 序列化为 JSON 数据类型
    /// - Parameters:
    ///   - context: 提供发起请求时的上下文信息供内部使用(createTask 时传入的 context)
    ///   - response: 原始,待序列化的 Response
    /// - Throws: 序列化过程报错
    public func serialize(context: ECONetworkServiceContext, response: ECONetworkResponseOrigin) throws -> JSON? {
        guard let data = response.bodyData else { return nil }
        return try JSON(data: data)
    }
}
