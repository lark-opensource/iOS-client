//
//  OpenPluginNavigationBar.swift
//  OPPlugin
//
//  Created by yi on 2021/3/23.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import TTMicroApp
import ECOProbe
import OPSDK
import WebBrowser
import LKCommonsLogging
import LarkContainer

final class OpenPluginNavigationBar: OpenBasePlugin {

    func setNavigationBarTitle(params: OpenAPISetNavigationBarTitleParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        
        guard let controller = gadgetContext.getControllerElseFailure(context.apiTrace, callback) else {
            return
        }

        let uniqueID = gadgetContext.uniqueID
        guard let title = params.title else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam).setOuterMessage(BundleI18n.OPPlugin.title_null()).setErrno(OpenAPICommonErrno.invalidParam(.paramWrongType(param: "title")))
            callback(.failure(error: error))
            return

        }
        let result = setInnerNavigationBarTitle(title: title, uniqueID: uniqueID, controller: controller)
        if result {
            callback(.success(data: nil))
        } else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setOuterMessage("can not find related page").setErrno(OpenAPICommonErrno.internalError)
            callback(.failure(error: error))
            return

        }
    }
    
    func showNavigationBarLoading(params: OpenAPIBaseParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let appVC = getAppPageElseFailure(context, gadgetContext, callback) else {
            return
        }
        let navigationBarHidden = appVC.pageConfig?.window?.navigationStyle == "custom"
        if navigationBarHidden {
            callback(.success(data: nil))
        } else {
            if let naviVC = appVC.navigationController as? BDPNavigationController  {
                naviVC.setNavigationBarLoading(true, viewController: appVC)
                callback(.success(data: nil))
            } else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setOuterMessage("navigationBar not exsit in current page").setErrno(OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
            }
        }
    }
    
    func hideNavigationBarLoading(params: OpenAPIBaseParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let appVC = getAppPageElseFailure(context, gadgetContext, callback) else {
            return
        }
        let navigationBarHidden = appVC.pageConfig?.window?.navigationStyle == "custom"
        if navigationBarHidden {
            callback(.success(data: nil))
        } else {
            if let naviVC = appVC.navigationController as? BDPNavigationController  {
                naviVC.setNavigationBarLoading(false, viewController: appVC)
                callback(.success(data: nil))
            } else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setOuterMessage("navigationBar not exsit in current page").setErrno(OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
            }
        }
    }
    
    func hideHomeButton(params: OpenAPIBaseParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let appVC = getAppPageElseFailure(context, gadgetContext, callback) else {
            return
        }
        appVC.canShowHomeButton = false
        appVC.updateNavigationBarStyle(false)
        callback(.success(data: nil))
    }

    func setInnerNavigationBarTitle(title: String, uniqueID: OPAppUniqueID, controller: UIViewController) -> Bool {
        if uniqueID.appType == .webApp {
            // 按照 https://bytedance.feishu.cn/docs/doccn0k42BSp3FYqY8KMnvaHFMc 评审要求，去除导致KA问题「最大之错误」的API在网页调用，没有修改任何其他逻辑
            return false
        }
        guard let task = BDPTaskManager.shared()?.getTaskWith(uniqueID) else {
            return false
        }

        guard let container = task.containerVC as? BDPAppContainerController else {
            return false
        }
        guard let pageViewController = container.appController?.currentAppPage() else {
            return false
        }
        var pageVC = pageViewController
        if let isInteractive = pageVC.transitionCoordinator?.isInteractive, isInteractive {
            let fromVC  = pageVC.transitionCoordinator?.viewController(forKey: UITransitionContextViewControllerKey.from)
            if let fromVC = fromVC as? BDPAppPageController {
                pageVC = fromVC
            }
        }
        pageVC.customNavigationBarTitle = title
        pageVC.pageConfig?.originWindow.navigationBarTitleText = title
        if let appPageController = pageVC as? BDPAppPageController {
            // 更新半屏的导航栏，下面更新subNavi的title在半屏下会缺失，且半屏为自定义的导航
            appPageController.updateXscreenNavigationBarTitle(title)
        }
        if let subNavi = pageVC.navigationController as? BDPNavigationController {
            subNavi.setNavigationItemTitle(title, viewController: pageVC)
        } else {
            pageVC.title = title
        }
        /*
        return false
         */
        return true //  修复上面明明已经成功更换title却号称false的缺陷
    }
    
    private func getAppPageElseFailure(_ context: OpenAPIContext, _ gadgetContext: GadgetAPIContext, _ callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) -> BDPAppPageController? {
        guard let controller = gadgetContext.getControllerElseFailure(context.apiTrace, callback) else {
            return nil
        }
        guard let appVC = BDPAppController.currentAppPageController(controller, fixForPopover: false) else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setOuterMessage("can not find current page controller").setErrno(OpenAPICommonErrno.internalError)
            callback(.failure(error: error))
            return nil
        }
        return appVC
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "setNavigationBarTitle", pluginType: Self.self, paramsType: OpenAPISetNavigationBarTitleParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.setNavigationBarTitle(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        
        registerInstanceAsyncHandlerGadget(for: "hideNavigationBarLoading", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.hideNavigationBarLoading(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        
        registerInstanceAsyncHandlerGadget(for: "showNavigationBarLoading", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.showNavigationBarLoading(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        
        registerInstanceAsyncHandlerGadget(for: "hideHomeButton", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.hideHomeButton(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: "setNavigationBarColor", pluginType: Self.self, paramsType: OpenAPISetNavigationBarColorParams.self) { this, params, context, gadgetContext, callback in
            // 若网页应用
            if WebMetaNavigationBarExtensionItem.isNavBgAndFgColorEnabled() && context.uniqueID?.appType == .webApp {
                guard let browser = context.controller as? WebBrowser else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError).setMonitorMessage("browser is nil")
                    callback(.failure(error: error))
                    context.apiTrace.error("web app setnavigationbarcolor api error: \(error)")
                    return
                }
                guard let item = browser.resolve(NavigationBarStyleExtensionItem.self) else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError).setMonitorMessage("navbaritem is nil")
                    callback(.failure(error: error))
                    context.apiTrace.error("web app setnavigationbarcolor api error: \(error)")
                    return
                }
                let bgColorStr = params.backgroundColor.trimmingCharacters(in: .whitespacesAndNewlines)
                context.apiTrace.info("web app setnavigationbarcolor api bgcolor: \(bgColorStr)")
                var bgColor: UIColor? = WebMetaNavigationBarExtensionItem.colorFrom(bgColorStr, fgColor: false)
                item.isBarColorApi = true
                item.updateBarBgColor(browser: browser, color: bgColor)
                
                let fgColorStr = params.frontColor.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                context.apiTrace.info("web app setnavigationbarcolor api fgcolor: \(fgColorStr)")
                var fgColor: UIColor? = WebMetaNavigationBarExtensionItem.colorFrom(fgColorStr, fgColor: true)
                item.isBarColorApi = true
                item.updateBarFgColor(browser: browser, color: fgColor)
                callback(.success(data: nil))
                return
            }
            // 若小程序
            guard gadgetContext.uniqueID.appType == .gadget else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError).setMonitorMessage("is not gadget").setErrno(OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
                return
            }
            let lowerFColorStr = params.frontColor.lowercased()
            guard let container = BDPModuleManager(of: .gadget)
                .resolveModule(with: BDPContainerModuleProtocol.self) as? BDPContainerModuleProtocol else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setMonitorMessage("has no BDPContainerModuleProtocol").setErrno(OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
                context.apiTrace.error("has no BDPContainerModuleProtocol")
                return
            }
            // Tips 这里是从BDPContainerModule完全平移逻辑，目的是按照API组要求不要使用BDPPluginContext，未修改任何逻辑
            guard let appVC = BDPAppController.currentAppPageController(gadgetContext.controller, fixForPopover: false) else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError).setMonitorMessage("BDPAppController.currentAppPageController get no apppagevc").setErrno(OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
                return
            }
            guard appVC.isKind(of: BDPAppPageController.self) else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError).setMonitorMessage("apppagevc is not BDPAppPageController").setErrno(OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
                return
            }
            appVC.pageConfig?.window?.setNavigationBarBackgroundColorByAPI(params.backgroundColor)
            appVC.pageConfig?.window?.setNavigationBarTextStyleByAPI(lowerFColorStr == "#ffffff" ? "white" : "black")
            appVC.updateStyle(false)
            appVC.updateStatusBarStyle(false)
            appVC.setNeedsStatusBarAppearanceUpdate()
            callback(.success(data: nil))
        }
    }
}
