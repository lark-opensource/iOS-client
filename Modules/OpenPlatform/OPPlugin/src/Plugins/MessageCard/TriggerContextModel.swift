//
//  TriggerContextModel.swift
//  OPPlugin
//
//  Created by lilun.ios on 2021/4/19.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIGetTriggerContextParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "triggerCode", validChecker: { !$0.isEmpty })
    public var triggerCode: String

    /// 属性自定义检查器
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_triggerCode]
    }
}

final class OpenAPIGetTriggerContextResult: OpenAPIBaseResult {
    /// 业务绑定的会话ID
    public let openChatId: String
    /// 业务类型
    public let bizType: String
    /// 初始化方法
    public init(openChatId: String, bizType: String) {
        self.openChatId = openChatId
        self.bizType = bizType
        super.init()
    }
    /// 返回打包结果
    public override func toJSONDict() -> [AnyHashable : Any] {
        return [
            "openChatId": openChatId,
            "bizType": bizType
        ]
    }
}
