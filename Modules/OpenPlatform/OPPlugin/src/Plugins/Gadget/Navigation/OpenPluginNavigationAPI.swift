//
//  OpenPluginNavigationAPI.swift
//  OPPlugin
//
//  Created by baojianjun on 2023/6/30.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import TTMicroApp
import OPFoundation
import LarkContainer

final class OpenPluginNavigationAPI: OpenBasePlugin {
    
    enum APIName: String, CaseIterable {
        case navigateTo
        case navigateBack
        case reLaunch
        case redirectTo
        case switchTab
        
        var mirror: OpenPluginNavigationAPI.AsyncAPIHandler {
            switch self {
            case .navigateTo:
                return OpenPluginNavigationAPI.navigateTo
            case .navigateBack:
                return OpenPluginNavigationAPI.navigateBack
            case .reLaunch:
                return OpenPluginNavigationAPI.reLaunch
            case .redirectTo:
                return OpenPluginNavigationAPI.redirectTo
            case .switchTab:
                return OpenPluginNavigationAPI.switchTab
            }
        }
    }
    
    func navigateTo(params: OpenPluginAPIAdapterParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginAPIAdapterResult>) -> Void) {
        guard let routeManager = routeManager(with: context, gadgetContext, callback) else {
            return
        }
        
        routeManager.navigate(to: params.params) {
            callback(.postProcess($0, $1))
        }
    }
    
    func navigateBack(params: OpenPluginAPIAdapterParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginAPIAdapterResult>) -> Void) {
        guard let routeManager = routeManager(with: context, gadgetContext, callback) else {
            return
        }
        
        routeManager.navigateBack(params.params) {
            callback(.postProcess($0, $1))
        }
    }
    
    func reLaunch(params: OpenPluginAPIAdapterParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginAPIAdapterResult>) -> Void) {
        guard let routeManager = routeManager(with: context, gadgetContext, callback) else {
            return
        }
        
        routeManager.reLaunch(params.params) {
            callback(.postProcess($0, $1))
        }
    }
    
    func redirectTo(params: OpenPluginAPIAdapterParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginAPIAdapterResult>) -> Void) {
        guard let routeManager = routeManager(with: context, gadgetContext, callback) else {
            return
        }
        
        routeManager.redirect(to: params.params) {
            callback(.postProcess($0, $1))
        }
    }
    
    func switchTab(params: OpenPluginAPIAdapterParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginAPIAdapterResult>) -> Void) {
        guard let routeManager = routeManager(with: context, gadgetContext, callback) else {
            return
        }
        
        routeManager.switchTab(params.params) {
            callback(.postProcess($0, $1))
        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        guard OPSDKFeatureGating.apiDynamicDispatchFromPMEnable() else {
            return
        }
        APIName.allCases.forEach { registerAsync(apiName: $0, handler: $0.mirror) }
    }
}

// MARK: Register

extension OpenPluginNavigationAPI {
    func routeManager(with context: OpenAPIContext, _ gadgetContext: GadgetAPIContext, _ callback: @escaping (OpenAPIBaseResponse<OpenPluginAPIAdapterResult>) -> Void) -> BDPAppRouteManager? {
        let uniqueID = gadgetContext.uniqueID
        
        let errorHandler: (String) -> BDPAppRouteManager? = { errMsg in
            context.apiTrace.error(errMsg)
            callback(.failure(error: .init(errno: OpenAPICommonErrno.internalError).setMonitorMessage(errMsg)))
            return nil
        }
        
        guard let task = BDPTaskManager.shared().getTaskWith(uniqueID) else {
            return errorHandler("uniqueID: \(uniqueID) task not found")
        }
        
        guard let container = task.containerVC as? BDPAppContainerController else {
            return errorHandler("uniqueID: \(uniqueID) container not found")
        }
        
        guard let appController = container.appController else {
            return errorHandler("uniqueID: \(uniqueID) appController not found")
        }
        
        guard let routeManager = appController.routeManager else {
            return errorHandler("uniqueID: \(uniqueID) routeManager not found")
        }
        return routeManager
    }
    
    typealias AsyncAPIHandler = (
        _ this: OpenPluginNavigationAPI
    ) -> OpenBasePlugin.AsyncHandlerGadget<OpenPluginAPIAdapterParams, OpenPluginAPIAdapterResult>
    
    private func registerAsync(apiName: APIName, handler: @escaping AsyncAPIHandler) {
        registerInstanceAsyncHandlerGadget(for: apiName.rawValue, pluginType: Self.self, paramsType: OpenPluginAPIAdapterParams.self, resultType: OpenPluginAPIAdapterResult.self) { try handler($0)($1, $2, $3, $4) }
    }
}
