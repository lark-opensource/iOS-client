//
//  OpenPluginChatBadgeModel.swift
//  OPPlugin
//
//  Created by 刘焱龙 on 2023/3/17.
//

import Foundation
import LarkOpenAPIModel

final class OpenPluginChatBadgeChangeParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "openChatId",
                          defaultValue: "")
    var openChatId:String

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_openChatId]
    }
}
