//
//  OpenWorkerModel.swift
//  OPPlugin
//
//  Created by yi on 2021/7/6.
//

import Foundation
import LarkOpenAPIModel

class OpenAPIWorkerParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "key", validChecker: {
        !$0.isEmpty
    })
    public var key: String

    @OpenAPIOptionalParam(jsonKey: "data")
    public var data: [AnyHashable: Any]?

    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_key, _data]
    }
}

@objcMembers
class OpenAPICreateWorkerResult: OpenAPIBaseResult {

    public var postMessage: (@convention(block) ([AnyHashable: Any]) -> Any?)? = nil
    public var onMessage: (@convention(block) (JSValue?) -> Any?)?
    public var terminate: (@convention(block) (JSValue?) -> Any?)?

    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["__nativeJsObject__": [["key": "comment_for_gadget", "value": ["postMessage": postMessage, "onMessage": onMessage, "terminate": terminate]]]]
    }
}

class OpenAPIWorkerTransferMessageParams: OpenAPIBaseParams {
    public var data: [AnyHashable: Any] = [:]

    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        self.data = params
    }
}

