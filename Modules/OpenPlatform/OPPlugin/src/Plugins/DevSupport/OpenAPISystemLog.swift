//
//  OpenAPISystemLog.swift
//  OPPlugin
//
//  Created by 窦坚 on 2021/6/17.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import LarkContainer

final class OpenAPISystemLog: OpenBasePlugin {

    public func systemLog(params: OpenAPISystemLogModel, context: OpenAPIContext, gadgetContext: OPAPIContextProtocol, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        BDPTracker.event(params.event, attributes: params.data, uniqueID: gadgetContext.uniqueID)
        callback(.success(data: nil))
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "systemLog", pluginType: Self.self, paramsType: OpenAPISystemLogModel.self, resultType: OpenAPIBaseResult.self) { (this, params, context,gadgetContext, callback) in
            
            this.systemLog(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }

}
