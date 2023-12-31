//
//  OpenDiagnoseCommands.swift
//  OPPlugin
//
//  Created by  豆酱 on 2021/5/14.
//

import Foundation
import OPPluginManagerAdapter
import LarkOpenAPIModel

final class OpenAPIExecDiagnoseCommandsParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "commands")
    public var commands: [[AnyHashable: Any]]

    public convenience init(commands: [[AnyHashable: Any]]) throws {
        try self.init(with: ["commands": commands])
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_commands]
    }
}

final class OpenAPIExecDiagnoseCommandsResult: OpenAPIBaseResult {
    public let result: [AnyHashable: Any]
    public init(result: [AnyHashable: Any]) {
        self.result = result
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return result
    }
}
