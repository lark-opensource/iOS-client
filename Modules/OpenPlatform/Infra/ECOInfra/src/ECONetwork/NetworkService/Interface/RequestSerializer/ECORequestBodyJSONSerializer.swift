//
//  ECORequestBodyJSONSerializer.swift
//  ECOInfra
//
//  Created by MJXin on 2021/6/4.
//

import Foundation
import LKCommonsLogging
public final class ECORequestBodyJSONSerializer: ECONetworkRequestSerializer {
    static let logger = Logger.oplog(ECORequestBodyJSONSerializer.self, category: "ECONetwork")
    let options: JSONSerialization.WritingOptions
    public init(options: JSONSerialization.WritingOptions = []) {
        self.options = options
    }
    /// 将入参序列化为 bodyData, 最终将序列化为 Data , 放在 httpbody 上
    /// 使用于 POST
    /// - Parameters:
    ///   - context: 提供发起请求时的上下文信息供内部使用(createTask 时传入的 context)
    ///   - request: 未经序列化的 request, Serializer 根据自身需求使用内部数据
    ///   - params: 请求时同步带入的入参,  描述当前接口的业务信息.
    public func serialize(context: ECONetworkServiceContext, request: ECONetworkRequestOrigin, params: [String: Any]) throws -> ECONetworkSerializeResult {
        var body: [String: Any] = request.bodyFields
        body = body.merging(params) {
            // 业务数据覆盖中间件的公参, 但这不应该发生, 代表有内容被吃掉了
            assertionFailure("merge new object to existed key, first:\($0), second:\($1)")
            return $1
        }
        let bodyData = try JSONSerialization.data(withJSONObject: body, options: options)
        return .bodyData(bodyData, ContentType.json.toString())
    }
}
