//
//  OpenNavigationBarModel.swift
//  OPPlugin
//
//  Created by yi on 2021/3/23.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPISetNavigationBarTitleParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "title")
    public var title: String?

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_title]
    }
}

final class OpenAPISetNavigationBarColorParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "frontColor", validChecker: {
        $0.lowercased() == "#ffffff" || $0.lowercased() == "#000000"
    })
    public var frontColor: String

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "backgroundColor", validChecker: {
        !$0.isEmpty && !$0.hasPrefix("0x") && UIColor.isValidColorHexString($0)
    })
    public var backgroundColor: String

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_frontColor, _backgroundColor]
    }
}
