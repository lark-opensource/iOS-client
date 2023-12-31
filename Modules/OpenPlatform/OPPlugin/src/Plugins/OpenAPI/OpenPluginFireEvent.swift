//
//  OpenPluginFireEvent.swift
//  OPPlugin
//
//  Created by yi on 2021/3/4.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import TTMicroApp
import ECOProbe
import OPSDK
import OPFoundation
import LarkContainer

final class OpenPluginFireEvent: OpenBasePlugin {

    func fireEvent(params: OpenAPIFireEventParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        
        switch params.preCheck {
        case .isVCActive:
            if !gadgetContext.isVCActive {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("app \(gadgetContext.uniqueID) VC is inactive, can not fire event")
                return .failure(error: error)
            }
        case .shouldInterruption:
            if gadgetContext.shouldInterruption {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("app \(gadgetContext.uniqueID) is interrupted, can not fire event")
                return .failure(error: error)
            }
        case .none:
            break
        }
        var result = false
        switch params.scene {
        case .normal:
            result = gadgetContext.fireEvent(event: params.event, sourceID: params.sourceID, data: params.data)
            break
        case .render:
            result = gadgetContext.fireEventToRender(event: params.event, sourceID: params.sourceID, data: params.data)
            break
        case .worker:
            result = gadgetContext.fireEventToWorker(event: params.event, sourceID: params.sourceID, data: params.data, source: params.sourceType)
            break
        }
        if !result {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("gadgetContext fireEvent error")
            return .failure(error: error)
        }
        return .success(data: nil)
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceSyncHandlerGadget(for: "fireEvent", pluginType: Self.self, paramsType: OpenAPIFireEventParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext) -> OpenAPIBaseResponse<OpenAPIBaseResult> in
            
            return this.fireEvent(params: params, context: context, gadgetContext: gadgetContext)
        }
    }
}
