//
//  OpenPluginGadgetDynamicRenderAPI.swift
//  OPPluginBiz
//
//  Created by baojianjun on 2023/6/30.
//

import Foundation
import LarkOpenAPIModel
import LarkOpenPluginManager
import OPPluginManagerAdapter
import TTMicroApp
import LarkContainer

final class OpenPluginGadgetDynamicRenderAPI: OpenBasePlugin {
    
    enum APIName: String {
        case getCurrentRoute
        case disableScrollBounce
        case endEditing
    }
    
    // 异步, 不强制在主线程
    func getCurrentRoute(
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping(OpenAPIBaseResponse<OpenPluginGetCurrentRouteResult>) -> Void)
    {
        guard let appPage = context.enginePageForComponent as? BDPAppPage else {
            let errMsg = "cannot find appPage"
            context.apiTrace.error(errMsg)
            callback(.failure(error: .init(errno: OpenAPICommonErrno.internalError).setMonitorMessage(errMsg)))
            return
        }
        callback(.success(data: .init(route: appPage.bap_path)))
    }
    
    // 异步, 强制在主线程
    func disableScrollBounce(
        params: OpenPluginAPIAdapterParams,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping(OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void)
    {
        guard let appPage = context.enginePageForComponent as? BDPAppPage else {
            let errMsg = "cannot find appPage"
            context.apiTrace.error(errMsg)
            callback(.failure(error: .init(errno: OpenAPICommonErrno.internalError).setMonitorMessage(errMsg)))
            return
        }
        let disable = params.params["disable"] as? Bool
        appPage.scrollView.bounces = !(disable ?? false)
        callback(.success(data: nil))
    }
    
    // 异步, 强制在主线程
    func endEditing(
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping(OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void)
    {
        guard let appPage = context.enginePageForComponent as? BDPAppPage else {
            let errMsg = "cannot find appPage"
            context.apiTrace.error(errMsg)
            callback(.failure(error: .init(errno: OpenAPICommonErrno.internalError).setMonitorMessage(errMsg)))
            return
        }
        appPage.endEditing(true)
        callback(.success(data: nil))
    }
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        guard OPSDKFeatureGating.apiDynamicDispatchFromPMEnable() else {
            return
        }
        registerInstanceAsyncHandlerGadget(for: APIName.getCurrentRoute.rawValue, pluginType: Self.self, resultType: OpenPluginGetCurrentRouteResult.self) { this, _, context, gadgetContext, callback in
            this.getCurrentRoute(context: context, gadgetContext: gadgetContext, callback: callback)
        }
        
        registerInstanceAsyncHandlerGadget(for: APIName.disableScrollBounce.rawValue, pluginType: Self.self, paramsType: OpenPluginAPIAdapterParams.self) { this, params, context, gadgetContext, callback in
            this.disableScrollBounce(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        
        registerInstanceAsyncHandlerGadget(for: APIName.endEditing.rawValue, pluginType: Self.self) { this, _, context, gadgetContext, callback in
            this.endEditing(context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}
