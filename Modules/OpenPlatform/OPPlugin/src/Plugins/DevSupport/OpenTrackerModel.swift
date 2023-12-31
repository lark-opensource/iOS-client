//
//  OpenTrackerModel.swift
//  OPPlugin
//
//  Created by yi on 2021/2/18.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIReportAnalyticsParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "event", defaultValue: "")
    public var event: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "value", defaultValue: [AnyHashable: Any]())
    public var value: [AnyHashable: Any]

    public convenience init(event: String, value: [AnyHashable: Any]) throws {
        let dict: [String: Any] = ["event": event, "value": value]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_event, _value]
    }

}
