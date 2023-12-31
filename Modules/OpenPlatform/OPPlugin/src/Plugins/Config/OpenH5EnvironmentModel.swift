//
//  OpenH5EnvironmentModel.swift
//  OPPlugin
//
//  Created by yi on 2021/2/18.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIGetEnvironmentVariablesResult: OpenAPIBaseResult {
    public let nativeTMAConfig: [AnyHashable: Any]
    public init(nativeTMAConfig: [AnyHashable: Any]) {
        self.nativeTMAConfig = nativeTMAConfig
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["nativeTMAConfig": nativeTMAConfig]
    }
}

