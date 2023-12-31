//
//  OpenAPISetTiming.swift
//  OPPlugin
//
//  Created by 窦坚 on 2021/7/7.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import TTMicroApp
import LarkContainer

final class OpenAPISetTiming: OpenBasePlugin {

    func setTiming(params: OpenAPISetTimingModel, context: OpenAPIContext, gadgetContext: OPAPIContextProtocol, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
    
        let data = params.data as NSDictionary
        for (key, value) in data {
            if let value = value as? NSNumber {
                let task = BDPTaskManager.shared()?.getTaskWith(gadgetContext.uniqueID)
                let num: Double = value.doubleValue * 0.001
                task?.performanceMonitor?.timing("\(key)", value: num)
            }
        }
        callback(.success(data: nil))
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "setTiming", pluginType: Self.self, paramsType: OpenAPISetTimingModel.self, resultType: OpenAPIBaseResult.self) { (this, params, context,gadgetContext, callback) in
            
            this.setTiming(params: params, context: context,gadgetContext: gadgetContext, callback: callback)
        }
    }
}
