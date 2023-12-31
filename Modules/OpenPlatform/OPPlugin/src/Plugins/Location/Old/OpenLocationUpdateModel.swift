//
//  OpenLocationUpdateModel.swift
//  OPPlugin
//
//  Created by laisanpin on 2021/5/21.
//  持续定位入参

import Foundation
import LarkOpenAPIModel
import CoreLocation

final class OpenAPILocationUpdateParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "type", defaultValue: "wgs84", validChecker: {
        $0 == "wgs84" || $0 == "gcj02"
    })
    public var type: String

    //best代表kCLLocationAccuracyBest, high代表kCLLocationAccuracyHundredMeters
    @OpenAPIRequiredParam(userOptionWithJsonKey: "accuracy", defaultValue: "high", validChecker: {
        $0 == "high" || $0 == "best"
    })
    public var accuracy: String

    public convenience init(type: String,
                            accuracy: String) throws {
        var dict = [String : Any]()
        dict["type"] = type
        dict["accuracy"] = accuracy

        // init dict here
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        // set checkable properties here
        return [_type, _accuracy]
    }
}
