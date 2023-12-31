//
//  OpenAPIReportJsRuntimeErrorModel.swift
//  OPPlugin
//
//  Created by 窦坚 on 2021/7/5.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIReportJsRuntimeErrorModel: OpenAPIBaseParams {

    @OpenAPIOptionalParam(jsonKey:"message")
    public var message: String?

    @OpenAPIOptionalParam(jsonKey:"stack")
    public var stack: String?

    @OpenAPIOptionalParam(jsonKey:"errorType")
    public var errorType: String?

    @OpenAPIOptionalParam(jsonKey:"extend")
    public var extend: String?

    @OpenAPIOptionalParam(jsonKey:"worker")
    public var worker: String? // worker 名字

    public convenience init(message: String, stack: String, errorType: String, extend: String, worker: String) throws {
        let dict: [String: Any] = ["message": message, "stack": stack, "errorType": errorType, "extend": extend, "worker": worker]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_message, _stack, _errorType, _extend, _worker]
    }

}
