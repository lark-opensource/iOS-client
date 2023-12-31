//
//  OpenPluginLifeCycle.swift
//  OPPlugin
//
//  Created by yi on 2021/4/2.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import TTMicroApp
import LKCommonsLogging
import LarkSetting
import OPSDK
import LarkContainer

final class OpenPluginLifeCycle: OpenBasePlugin {

    func exitMiniProgram(context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        
        let uniqueID = gadgetContext.uniqueID
        
        // 判断是否为主导航目前被封装到了OPGadgetRotationHelper中，不是很合理，但这里不写多份相同的实现
        if !userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.gadget.tabgadget.exit.disable"),
           OPGadgetRotationHelper.isTabGadget(uniqueID) {
            let error = OpenAPIError(errno: OpenAPIUiWindowErrno.tabGadgetNotSupport)
            callback(.failure(error: error))
            return
        }

        context.apiTrace.info("exitMiniProgram \(uniqueID)")
        let task = BDPTaskManager.shared()?.getTaskWith(uniqueID)
        let containerVC = task?.containerVC
        if ((containerVC?.navigationController) == nil) && ((containerVC?.presentingViewController) == nil) {
            BDPWarmBootManager.shared()?.cleanCache(with: uniqueID)
            context.apiTrace.error("containerVC is nil")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("containerVC is nil")
                .setErrno(OpenAPICommonErrno.internalError)
            callback(.failure(error: error))
            return
        }
        
        guard let controller = gadgetContext.getControllerElseFailure(context.apiTrace, callback) else {
            return
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad && OPTemporaryContainerService.isGadgetTemporaryEnabled() {
            if let gadgetContainer = OPApplicationService.current.getContainer(uniuqeID: uniqueID) {
                gadgetContainer.removeTemporaryTab()
            }
        }

        dismissPresentedViewControllerOfController(controller: controller) { [weak self] () in
            OPApplicationService.current.getContainer(uniuqeID: uniqueID)?.unmount(monitorCode: GDMonitorCode.exit_app_api_dismiss)
        }
        callback(.success(data: nil))
    }

    func dismissPresentedViewControllerOfController(controller: UIViewController, completion: @escaping () -> Void ) {
        let appPageController = BDPAppController.currentAppPageController(controller, fixForPopover: false)
        if let presentedViewController = appPageController?.presentedViewController, !presentedViewController.isBeingDismissed {
            appPageController?.dismiss(animated: false, completion: completion)
            return
        }
        completion()
    }

    func dismissViewController(controller: UIViewController, uniqueID: OPAppUniqueID) {
        if let navigationController = controller.navigationController {
            let viewControllers = navigationController.viewControllers
            if let mutableViewControllers = (viewControllers as NSArray).mutableCopy() as? NSMutableArray {
                if mutableViewControllers.contains(controller) {
                    mutableViewControllers.remove(controller)
                    if let controllers = mutableViewControllers.copy() as? [UIViewController] {
                        navigationController.setViewControllers(controllers , animated: false)
                    }
                }
            }
        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "exitMiniProgram", pluginType: Self.self) { (this, _, context, gadgetContext, callback) in
            
            this.exitMiniProgram(context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}
