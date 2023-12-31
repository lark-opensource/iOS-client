//
//  OpenPluginToast.swift
//  OPPlugin
//
//  Created by yi on 2021/3/15.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import ECOProbe
import LarkContainer
import TTMicroApp

final class OpenPluginToast: OpenBasePlugin {
    
    private class func showToast(params: OpenAPIShowToastParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {

        let uniqueID = gadgetContext.uniqueID

        let toastController = OpenPluginToast.presentBaseController(appType: uniqueID.appType, inController: gadgetContext.controller)
        OpenToastManager.shared.showToastWithModel(params: params, context: context, controller: toastController)
        callback(.success(data: nil))
    }

    private class func hideToast(params: OpenAPIBaseParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let controller = gadgetContext.getControllerElseFailure(context.apiTrace, callback) else {
            return
        }
        let window = controller.view.window
        OpenToastManager.shared.hideToast(window: window, context: context)
        callback(.success(data: nil))
    }

    private class func presentBaseController(appType: OPAppType, inController: UIViewController?) -> UIViewController? {
        var controller: UIViewController?
        switch appType {
        case .webApp:
            if EMAHUD.adaptWebApp {
                controller = inController
            } else {
                controller = nil
            }
            break
        case .widget, .gadget:
            controller = BDPAppController.currentAppPageController(inController, fixForPopover: false)
            break
        default:
            controller = BDPAppController.currentAppPageController(inController, fixForPopover: false)
            break
        }
        return controller
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerAsyncHandlerGadget(for: "showToast", paramsType: OpenAPIShowToastParams.self, handler: Self.showToast)
        
        registerAsyncHandlerGadget(for: "hideToast", handler: Self.hideToast)
    }
}
