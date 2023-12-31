//
//  OpenAPISystemLogModel.swift
//  OPPlugin
//
//  Created by 窦坚 on 2021/6/17.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPISystemLogModel: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "tag")
    public var event: String

    @OpenAPIOptionalParam(jsonKey: "data")
    public var data: [AnyHashable: Any]?

    public convenience init(event: String, data: [AnyHashable: Any]) throws {
        let dict: [String: Any] = ["event": event, "data": data]
        
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_event, _data]
    }

}
