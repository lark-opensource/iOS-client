//
//  OpenRouterModel.swift
//  OPPlugin
//
//  Created by yi on 2021/2/20.
//

import Foundation
import LarkOpenAPIModel
import OPPluginManagerAdapter
import TTMicroApp

final class OpenAPIOpenOuterURLParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "url", validChecker: {
        !$0.isEmpty
    })
    public var url: String

    public convenience init(url: String) throws {
        let dict: [String: Any] = ["url": url]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_url]
    }
}

final class OpenAPIOpenSchemaParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "schema", validChecker: {
        if OpenSchemaRefactorPolicy.refactorEnabled {
            return true
        } else {
            return !$0.isEmpty
        }
    })
    public var schema: String
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "external", defaultValue: false)
    public var external: Bool

    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        
        if !OpenSchemaRefactorPolicy.refactorEnabled {
            self.external = false
            if let externalParam = params["external"] as? Bool {
                self.external = externalParam
            } else if let externalParam = params["external"] as? NSNumber {
                self.external = (externalParam.intValue != 0)
            }
        }
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        if OpenSchemaRefactorPolicy.refactorEnabled {
            return [_schema, _external]
        } else {
            return [_schema]
        }
    }
}
