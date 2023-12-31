//
//  OpenPluginShare.swift
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

class OpenPluginShare: OpenBasePlugin {

    public func showShareMenu(context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        
        let uniqueID = gadgetContext.uniqueID
        let task = BDPTaskManager.shared()?.getTaskWith(uniqueID)

        var hideShareMenu = false
        if let common = BDPCommonManager.shared()?.getCommonWith(uniqueID), let model = OPUnsafeObject(common.model) {
            hideShareMenu = model.shareLevel == BDPAppShareLevel.black
        }
        let config = task?.config?.getPageConfig(byPath: task?.currentPage?.path)
        switch uniqueID.appType {
        case .gadget:
            config?.isHideShareMenu = hideShareMenu
            callback(.success(data: nil))
        default:
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
            callback(.failure(error: error))
        }
    }

    public func hideShareMenu(context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        
        let uniqueID = gadgetContext.uniqueID
        let task = BDPTaskManager.shared()?.getTaskWith(uniqueID)
        let config = task?.config?.getPageConfig(byPath: task?.currentPage?.path)
        switch uniqueID.appType {
        case .gadget:
            config?.isHideShareMenu = true
            callback(.success(data: nil))
        default:
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
            callback(.failure(error: error))
        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "showShareMenu", pluginType: Self.self, resultType: OpenAPIBaseResult.self) { (this, _, context, gadgetContext, callback) in
            
            this.showShareMenu(context: context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: "hideShareMenu", pluginType: Self.self, resultType: OpenAPIBaseResult.self) { (this, _, context, gadgetContext, callback) in
            
            this.hideShareMenu(context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}
