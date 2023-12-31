//
//  OpenPluginBlockErrorPageModel.swift
//  OPBlock
//
//  Created by doujian on 2022/8/3.
//

import LarkOpenAPIModel

public final class OpenPluginBlockErrorPageParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userOptionWithJsonKey: "errorMessage", defaultValue: "default error message")
    public var errorMessage: String

    @OpenAPIOptionalParam(jsonKey: "buttonText")
    public var buttonText: String?

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_errorMessage, _buttonText]
    }
}
