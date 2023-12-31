//
//  OPAPIHandlerBrightnessModel.swift
//  LarkOpenApis
//
//  Created by yi on 2021/2/2.
//

import Foundation
import UIKit
import LarkOpenAPIModel

final class OpenAPIGetScreenBrightnessResult: OpenAPIBaseResult {
    public var value: CGFloat
    public init(value: CGFloat) {
        self.value = value
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["value": value]
    }
}

final class OpenAPISetScreenBrightnessParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "value", validChecker: {
        $0 >= 0.0 && $0 <= 1.0
    })
    public var value: CGFloat

    public convenience init(value: CGFloat) throws {
        let dict: [String: Any] = ["value": value]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_value]
    }
}

final class OpenAPISetKeepScreenOnParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userOptionWithJsonKey: "keepScreenOn", defaultValue: true)
    public var keepScreenOn: Bool

    public convenience init(keepScreenOn: Bool = true) throws {
        let dict: [String: Any] = ["keepScreenOn": keepScreenOn]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_keepScreenOn]
    }
}
