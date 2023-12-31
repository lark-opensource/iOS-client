//
//  OpenToastManager.swift
//  OPPlugin
//
//  Created by yi on 2021/4/19.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import ECOProbe

final class OpenToastManager: NSObject {
    public static let shared = OpenToastManager()
    var toastView: EMAHUD?
    func showToastWithModel(params: OpenAPIShowToastParams, context: OpenAPIContext, controller: UIViewController?) {
        context.apiTrace.info("showToastWithModel")
        var duration: TimeInterval = params.duration > 0 ? (Double(params.duration) / 1000.0) : 1.5
        let window = controller?.view.window
        var view = controller?.view
        if let navController = controller as? UINavigationController {
            view = navController.topViewController?.view ?? navController.view
        }
        if view == nil {
            view = topVCView(window: window)
        }
        EMAHUD.removeHUD(on: view, window: window)
        var hudView: EMAHUD?
        if params.icon == "loading" {
            hudView = EMAHUD.showLoading(params.title, on: view, window: window, delay: duration, disableUserInteraction: params.mask)
        } else if params.icon == "success" {
            hudView = EMAHUD.showSuccess(params.title, on: view, window: window, delay: duration, disableUserInteraction: params.mask)
        } else if params.icon == "fail" {
            hudView = EMAHUD.showFailure(params.title, on: view, window: window, delay: duration, disableUserInteraction: params.mask)
        } else {
            hudView = EMAHUD.showTips(params.title, on: view, window: window, delay: duration, disableUserInteraction: params.mask)
        }
        toastView = hudView
    }

    func hideToast(window: UIWindow?, context: OpenAPIContext) {
        context.apiTrace.info("hideToast")
        toastView?.remove()
        EMAHUD.removeHUD(window: window)
        let view = topVCView(window: window)
        EMAHUD.removeHUD(on: view, window: window)

    }

    func topVCView(window: UIWindow?) -> UIView? {
        guard let window = window, let topVC = OPNavigatorHelper.topMostAppController(window: window) else {
            return nil
        }
        var view = topVC.view
        if topVC.isKind(of: UINavigationController.self) {
            var navController = topVC as? UINavigationController
            view = navController?.topViewController?.view ?? topVC.view
        }
        return view
    }
}
