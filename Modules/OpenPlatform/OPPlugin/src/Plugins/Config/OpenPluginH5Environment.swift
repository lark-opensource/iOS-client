//
//  OpenPluginH5Environment.swift
//  OPPlugin
//
//  Created by yi on 2021/2/18.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import ECOProbe
import LarkContainer

final class OpenPluginH5Environment: OpenBasePlugin {

    class func getEnvironmentVariables(params: OpenAPIBaseParams, context: OpenAPIContext) -> OpenAPIBaseResponse<OpenAPIGetEnvironmentVariablesResult> {
        let nativeTMAConfig: [String: Any] = [
            "navigationBarHidden": true,
            "tabbarHidden": true,
            "platform": "ios"
        ]
        let data = OpenAPIGetEnvironmentVariablesResult(nativeTMAConfig: nativeTMAConfig)
        return .success(data: data)
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerSyncHandler(for: "getEnvironmentVariables", resultType: OpenAPIGetEnvironmentVariablesResult.self, handler: Self.getEnvironmentVariables)
    }
}
