//
//  OpenDebuggerModel.swift
//  OPPlugin
//
//  Created by yi on 2021/2/18.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIConsoleLogOutputParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "payload", defaultValue: [AnyHashable: Any]())
    public var payload: [AnyHashable: Any]

    public convenience init(payload: [AnyHashable: Any]) throws {
        let dict: [String: Any] = ["payload": payload]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_payload]
    }
}

final class OpenAPILogManagerParams: OpenAPIBaseParams {
    
    public var logParams: [AnyHashable: Any]

    public required init(with params: [AnyHashable: Any]) throws {
        logParams = params
        try super.init(with: params)
    }
}
