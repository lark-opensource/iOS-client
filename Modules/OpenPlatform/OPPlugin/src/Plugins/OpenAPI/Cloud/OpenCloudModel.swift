//
//  OpenCloudModel.swift
//  OPPlugin
//
//  Created by yi on 2021/4/12.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPICallLightServiceParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "context")
    public var context: [AnyHashable: Any]

    public convenience init(context: [AnyHashable: Any]) throws {
        let dict: [String: Any] = ["context": context]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_context]
    }
}

final class OpenCallLightServiceResult: OpenAPIBaseResult {
    public var data: [AnyHashable: Any]

    public init(data: [AnyHashable: Any]) {
        self.data = data
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return data
    }
}
