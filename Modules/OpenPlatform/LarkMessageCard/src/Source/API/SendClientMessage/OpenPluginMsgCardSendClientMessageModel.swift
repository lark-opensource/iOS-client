//
//  OpenPluginUniversalCardSendClientMessageModel.swift
//  LarkOpenApis
//
//  GENERATED BY ANYCODE. DO NOT MODIFY!!!
//  TICKETID: 31152
//
//  类型声明默认为internal, 如需被外部Module引用, 请在上行添加
//  /** anycode-lint-ignore */
//  public
//  /** anycode-lint-ignore */

import Foundation
import LarkOpenAPIModel


// MARK: - OpenPluginUniversalCardSendClientMessageRequest
final class OpenPluginMsgCardSendClientMessageRequest: OpenAPIBaseParams {

    /// description: 组件tag
    @OpenAPIRequiredParam(
            userRequiredWithJsonKey: "tag")
    var tag: String

    /// description: 端通信业务方channel
    @OpenAPIRequiredParam(
            userRequiredWithJsonKey: "channel")
    var channel: String

    /// description: 端通信交互投递数据
    @OpenAPIRequiredParam(
            userRequiredWithJsonKey: "value")
    var value: String

    /// description: 组件ID
    @OpenAPIOptionalParam(
            jsonKey: "elementID")
    var elementID: String?

    /// description: 组件tag
    @OpenAPIOptionalParam(
            jsonKey: "name")
    var name: String?

    /// description: 端通信平台配置
    @OpenAPIOptionalParam(
            jsonKey: "platformConfig")
    var platformConfig: [AnyHashable: Any]?

    /// description: 失效时间
    @OpenAPIOptionalParam(
            jsonKey: "expiredTime")
    var expiredTime: String?

    /// description: 失效提示文案
    @OpenAPIOptionalParam(
            jsonKey: "expiredTips")
    var expiredTips: String?

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_tag, _channel, _value, _elementID, _name, _platformConfig, _expiredTime, _expiredTips]
    }
}
