//
//  OpenAPIProtocolPathToAbsPathModel.swift
//  OPPlugin
//
//  Created by xiangyuanyuan on 2021/11/30.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel

final class OpenAPIProtocolPathToAbsPathParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "protocolPath", validChecker: {
        !$0.isEmpty
    })
    var protocolPath: String

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_protocolPath]
    }
}

final class OpenAPIProtocolPathToAbsPathResult: OpenAPIBaseResult {
    public var absPath: String
    
    public init(absPath: String){
        self.absPath = absPath
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["absPath": absPath]
    }
}
