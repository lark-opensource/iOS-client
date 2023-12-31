//
//  OPAPIHandlerAccelerometerModel.swift
//  LarkOpenApis
//
//  Created by yi on 2021/2/2.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIEnableAccelerometerParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "enable", defaultValue: false)
    public var enable: Bool
    @OpenAPIOptionalParam(jsonKey: "interval")
    public var interval: String?

    public convenience init(enable: Bool = false, interval: String? = nil) throws {
        var dict: [String: Any] = ["enable": enable]
        if let interval = interval {
            dict["interval"] = interval
        }
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_enable, _interval]
    }
}
