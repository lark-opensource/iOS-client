//
//  OpenAPILogModel.swift
//  OPPlugin
//
//  Created by 王飞 on 2021/10/28.
//

import Foundation
import LarkOpenAPIModel

@objc(OpenAPILogModel)
final class OpenAPILogModel: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "message")
    var message: [AnyHashable]

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "level")
    var level: String

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "time")
    var time: TimeInterval

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        // add your checkable properties here
        return [_message, _level, _time]
    }
}
