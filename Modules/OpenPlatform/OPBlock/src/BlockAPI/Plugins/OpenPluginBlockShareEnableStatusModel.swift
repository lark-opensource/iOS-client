//
//  OpenPluginBlockShareEnableStatusModel.swift
//  OPBlock
//
//  Created by ByteDance on 2023/5/17.
//

import Foundation
import LarkOpenAPIModel

open class OpenPluginBlockShareEnableStatusRequest: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "isBlockEnableShare", defaultValue: false)
    public var enableShare: Bool

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_enableShare]
    }
}
