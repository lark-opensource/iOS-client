//
//  OpenPluginCanvasModel.swift
//  OPPlugin
//
//  Created by lixiaorui on 2021/4/12.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIMeasureTextParams: OpenAPIBaseParams {

    // declare your properties here
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "text")
    public var text: String

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "font")
    public var fonts: [String]

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "fontSize")
    public var fontSize: CGFloat

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        // add your checkable properties here
        return [_text, _fonts, _fontSize]
    }

}

final class OpenAPIMeasureTextResult: OpenAPIBaseResult {

    public let width: CGFloat

    public init(width: CGFloat) {
        self.width = width
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["data": ["width":width]]
    }
}
