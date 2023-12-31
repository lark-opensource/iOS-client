//
//  OpenAPIMonitorReportModel.swift
//  OPPlugin
//
//  Created by  窦坚 on 2021/5/31.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIMonitorReportParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userOptionWithJsonKey: "monitorEvents", defaultValue: [[AnyHashable: Any]]())
    public var monitorEvents: [[AnyHashable: Any]]

    public convenience init(monitorEvents: [AnyHashable: Any]) throws {
        let dict: [String: Any] = ["monitorEvents": monitorEvents]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_monitorEvents]
    }
}
