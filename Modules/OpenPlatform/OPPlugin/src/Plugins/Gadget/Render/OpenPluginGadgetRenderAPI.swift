//
//  OpenPluginGadgetRenderAPI.swift
//  OPPluginBiz
//
//  Created by baojianjun on 2023/6/29.
//

import Foundation
import LarkOpenAPIModel
import LarkOpenPluginManager
import OPPluginManagerAdapter
import TTMicroApp
import LarkContainer

final class OpenPluginGadgetRenderAPI: OpenBasePlugin {
    
    enum APIName: String {
        case reportTimeline
    }
    
    // 异步, 不强制在主线程
    func reportTimeline(
        params: OpenPluginReportTimelineRequest,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping(OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void)
    {
        let errorHandler: (String) -> Void = { errMsg in
            context.apiTrace.error(errMsg)
            callback(.failure(error: .init(errno: OpenAPICommonErrno.internalError).setMonitorMessage(errMsg)))
        }
        guard let engine = context.enginePageForComponent as? BDPWebView else {
            errorHandler("cannot find gadgetContext engine as BDPWebView")
            return
        }
        
        guard let phase = params.phase, phase == "DOMReady" else {
            errorHandler("phase: \(params.phase ?? "") is not DOMReady")
            return
        }
        
        guard let delegate = engine.bdpWebViewInjectdelegate,
        let handleReportTimelineDomReady = delegate.handleReportTimelineDomReady else {
            errorHandler("engine.bdpWebViewInjectdelegate is not responseTo handleReportTimelineDomReady")
            return
        }
        
        handleReportTimelineDomReady()
        callback(.success(data: nil))
    }
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        guard !OPBridgeRegisterOpt.bridgeRegisterOptDisable() else {
            return
        }
        registerInstanceAsyncHandlerGadget(for: APIName.reportTimeline.rawValue, pluginType: Self.self, paramsType: OpenPluginReportTimelineRequest.self) { this, params, context, gadgetContext, callback in
            this.reportTimeline(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}
