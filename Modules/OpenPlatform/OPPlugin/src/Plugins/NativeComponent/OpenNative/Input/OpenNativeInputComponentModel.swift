//
//  OpenNativeInputomponentModel.swift
//  OPPlugin
//
//  Created by xiongmin on 2022/4/14.
//

import Foundation
import LarkOpenAPIModel
import OPPluginManagerAdapter

// SetKeyboardModel
final class OpenNativeAPISetKeyboardParams: OpenAPIBaseParams {
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "cursor", defaultValue: 0)
    var cursor: Int
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "value", defaultValue: "")
    var value: String

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_value, _cursor]
    }
}

