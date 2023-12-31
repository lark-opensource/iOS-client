//
//  OpenAPIDeviceModel.swift
//  OPPlugin
//
//  Created by bytedance on 2021/4/20.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIGetPageSizeParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "htmlId", defaultValue: 0)
    public var htmlId: Int

    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_htmlId]
    }
}

class OpenPluginGetPageSizeResult: OpenAPIBaseResult {
    public let size: CGSize

    public init(size: CGSize) {
        self.size = size
        super.init()
    }

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["size": ["pageWidth" : size.width, "pageHeight" : size.height]]
    }
}
