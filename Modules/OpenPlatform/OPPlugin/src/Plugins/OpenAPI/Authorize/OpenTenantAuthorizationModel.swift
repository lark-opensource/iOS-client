//
//  OpenTenantAuthorizationModel.swift
//  OPPlugin
//
//  Created by yi on 2021/4/9.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIGetTenantAppScopesResult: OpenAPIBaseResult {
    public var scopes: [Any]

    public init(scopes: [Any]) {
        self.scopes = scopes
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["scopes": scopes]
    }
}

final class OpenAPIApplyTenantAppScopeResult: OpenAPIBaseResult {
    public var data: [AnyHashable : Any]

    public init(data: [AnyHashable : Any]) {
        self.data = data
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["data": data]
    }
}



