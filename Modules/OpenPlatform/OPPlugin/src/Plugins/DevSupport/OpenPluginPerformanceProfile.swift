//
//  OpenPluginPerformanceProfile.swift
//  OPPlugin
//
//  Created by ChenMengqi on 2022/12/14.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import TTMicroApp
import LarkContainer

final class OpenPluginPerformanceProfileParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "total", defaultValue: 0)
    var total: Int

    @OpenAPIRequiredParam(userOptionWithJsonKey: "index", defaultValue: 0)
    var index: Int

    @OpenAPIRequiredParam(userOptionWithJsonKey: "data", defaultValue: "")
    var data: String

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_total,_index, _data]
    }

}


final class OpenPluginPerformanceProfile: OpenBasePlugin {
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "sendDebugPerformanceData", pluginType: Self.self, paramsType: OpenPluginPerformanceProfileParams.self) { (_, params, _, callback) in
            BDPPerformanceProfileManager.sharedInstance().flushJSSDKPerformanceData(["data":params.data,
                                                                                     "total":params.total,
                                                                                     "index":params.index])
            callback(.success(data: nil))

        }
    }
}
