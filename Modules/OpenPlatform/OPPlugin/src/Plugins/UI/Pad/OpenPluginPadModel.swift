//
//  OpenPluginPadModel.swift
//  OPPlugin
//
//  Created by ChenMengqi on 2021/9/1.
//

import Foundation
import LarkOpenAPIModel

final class OpenPluginPadResult: OpenAPIBaseResult {
    public let displayScaleMode: String

    public init(displayScaleMode: String) {
        self.displayScaleMode = displayScaleMode
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["displayScaleMode": displayScaleMode]
    }
}

final class OpenPluginPadParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "displayScaleMode", validChecker:{
        $0 == "fullScreen" || $0 == "allVisible"
    })

    public var displayScaleMode: String?
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_displayScaleMode]
    }
}

