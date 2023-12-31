//
//  OpenPluginModal.swift
//  OPPlugin
//
//  Created by yi on 2021/4/6.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import TTMicroApp
import LKCommonsLogging
import LarkContainer

final class OpenPluginPullDownRefresh: OpenBasePlugin {

    func enablePullDownRefresh(params: OpenAPIBaseParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        
        let uniqueID = gadgetContext.uniqueID
        context.apiTrace.info("enablePullDownRefresh, app=\(uniqueID)")
        
        guard let controller = context.controller else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setMonitorMessage("controller is nil, has gadgetContext? \(context.gadgetContext != nil)")
            callback(.failure(error: error))
            return
        }
        if let topPageController = topAppPageControllerForController(controller: controller) {
            topPageController.appPage?.scrollView.bounces = true
            topPageController.appPage?.scrollView.needPullRefresh = true
            callback(.success(data: nil))
        } else {
            context.apiTrace.error("Can not find BDPAppController")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setMonitorMessage("Can not find BDPAppController")
            callback(.failure(error: error))
        }
    }
    
    func disablePullDownRefresh(params: OpenAPIBaseParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        
        let uniqueID = gadgetContext.uniqueID
        context.apiTrace.info("disablePullDownRefresh, app=\(uniqueID)")
        
        guard let controller = (context.gadgetContext)?.controller else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setMonitorMessage("controller is nil, has gadgetContext? \(context.gadgetContext != nil)")
            callback(.failure(error: error))
            return
        }
        if let topPageController = topAppPageControllerForController(controller: controller) {
            topPageController.appPage?.scrollView.bounces = false
            topPageController.appPage?.scrollView.needPullRefresh = false
            callback(.success(data: nil))
        } else {
            context.apiTrace.error("Can not find BDPAppController")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setMonitorMessage("Can not find BDPAppController")
            callback(.failure(error: error))
        }
    }

    private func topAppPageControllerForController(controller: UIViewController) -> BDPAppPageController? {
        guard let topVC = BDPAppController.currentAppPageController(controller, fixForPopover: false) as? BDPAppPageController else {
            return nil
        }
        return topVC
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "enablePullDownRefresh", pluginType: Self.self) { (this, params, context, gadgetContext, callback) in
            
            this.enablePullDownRefresh(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        
        registerInstanceAsyncHandlerGadget(for: "disablePullDownRefresh", pluginType: Self.self) { (this, params, context, gadgetContext, callback) in
            
            this.disablePullDownRefresh(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }

    }
}
