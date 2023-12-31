//
//  BlockSourceDetailModel.swift
//  OPPlugin
//
//  Created by lilun.ios on 2021/4/21.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIGetBlockSourceDetailParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "triggerCode", validChecker: { !$0.isEmpty })
    public var triggerCode: String

    /// 属性自定义检查器
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_triggerCode]
    }
}

final class OpenAPIGetBlockSourceDetailResult: OpenAPIBaseResult {
    /// 消息查询结果
    public let messageDetail: [String: Any]
    /// 初始化方法
    public init(messageDetail: [String: Any]) {
        self.messageDetail = messageDetail
        super.init()
    }
    /// 返回打包结果
    public override func toJSONDict() -> [AnyHashable : Any] {
        return messageDetail
    }
}
