//
//  OpenPluginPullDownRefreshAPI.swift
//  OPPlugin
//
//  Created by baojianjun on 2023/6/30.
//

import Foundation
import LarkOpenAPIModel
import LarkOpenPluginManager
import OPPluginManagerAdapter
import TTMicroApp
import LarkContainer

final class OpenPluginPullDownRefreshAPI: OpenBasePlugin {
    
    enum APIName: String {
        case startPullDownRefresh
        case stopPullDownRefresh
    }
    
    // 异步, 强制在主线程
    func startPullDownRefresh(context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping(OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let pageVC = guardEnablePullDownRefresh(context, gadgetContext, callback) else {
            return
        }
        pageVC.appPage?.scrollView.tmaTriggerPullDown()
        callback(.success(data: nil))
    }
    
    // 异步, 强制在主线程
    func stopPullDownRefresh(context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping(OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let pageVC = guardEnablePullDownRefresh(context, gadgetContext, callback) else {
            return
        }
        pageVC.appPage?.scrollView.tmaFinishPullDown(withSuccess: true)
        callback(.success(data: nil))
    }
    
    func guardEnablePullDownRefresh(_ context: OpenAPIContext, _ gadgetContext: GadgetAPIContext, _ callback: @escaping(OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) -> BDPAppPageController? {
        let errorHandler: (String) -> BDPAppPageController? = { errMsg in
            context.apiTrace.error(errMsg)
            callback(.failure(error: .init(errno: OpenAPICommonErrno.internalError).setMonitorMessage(errMsg)))
            return nil
        }
        guard let appVC = gadgetContext.controller as? BDPAppController,
              let pageVC = appVC.currentAppPage() else {
            return errorHandler("can not get gadget page")
        }
        guard let window = pageVC.pageConfig?.window,
              let enablePullDownRefresh = window.enablePullDownRefresh,
              enablePullDownRefresh.boolValue else {
            return errorHandler("window.enablePullDownRefresh is false!")
        }
        return pageVC
    }
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        guard OPSDKFeatureGating.apiDynamicDispatchFromPMEnable() else {
            return
        }
        registerInstanceAsyncHandlerGadget(for: APIName.startPullDownRefresh.rawValue, pluginType: Self.self, paramsType: OpenAPIBaseParams.self) { this, _, context, gadgetContext, callback in
            this.startPullDownRefresh(context: context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: APIName.stopPullDownRefresh.rawValue, pluginType: Self.self, paramsType: OpenAPIBaseParams.self) { this, _, context, gadgetContext, callback in
            this.stopPullDownRefresh(context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}

