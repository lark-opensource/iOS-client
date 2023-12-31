//
//  OpenPluginAppReview.swift
//  OPPlugin
//
//  Created by xiangyuanyuan on 2021/12/23.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import TTMicroApp
import OPPluginManagerAdapter
import EENavigator
import OPSDK
import OPFoundation
import WebBrowser
import Swinject
import LarkContainer
import LarkOpenAPIModel

final class OpenPluginAppReview: OpenBasePlugin {
    
    @Provider var appReviewManager: AppReviewService
    
    func endAppReview(params: OpenAPIEndAppReviewParams,
                             context: OpenAPIContext,
                             callback: @escaping(OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        // 判断是否由评分小程序调用的api
        guard let appId = context.uniqueID?.appID,
              appId == appReviewManager.opAppReviewConfig?.appReviewAppid else {
                  context.apiTrace.error("endAppReview can only be called by scoring gadget")
                  let error = OpenAPIError(code: GetAppReviewErrorCode.featureNotSupport)
                      .setMonitorMessage("endAppReview can only be called by scoring gadget")
                  callback(.failure(error: error))
                  return
        }
        appReviewManager.syncAppReview(appId: params.appId, trace: context.getTrace()) { (reviewInfo, error) in
            if error != nil {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("syncAppReview error")
                callback(.failure(error: error))
                return
            }
            callback(.success(data: nil))
            return
        }
    }
    
    func requestAppReview(context: OpenAPIContext,
                                 gadgetContext: GadgetAPIContext,
                                 callback: @escaping(OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        // 判断是否能唤起评分app
        guard let appId = context.uniqueID?.appID, appReviewManager.isAppReviewEnable(appId: appId) else {
            context.apiTrace.error("requestAppReview NotSupport")
            let error = OpenAPIError(code: GetAppReviewErrorCode.featureNotSupport)
                .setMonitorMessage("requestAppReview NotSupport")
            callback(.failure(error: error))
            return
        }
        let uniqueID = gadgetContext.uniqueID
        let completionHandler: ([AnyHashable: Any]?, Error?) -> Void = { [weak self] (result, error) in
            guard let self = self else {
                let errorMsg = "self is nil"
                context.apiTrace.error(errorMsg, error: error)
                let errorInfo = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage(errorMsg)
                callback(.failure(error: errorInfo))
                return
            }
            
            if error != nil {
                let errorMsg = "requestAppReview network error"
                context.apiTrace.error(errorMsg, error: error)
                let errorInfo = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage(errorMsg)
                callback(.failure(error: errorInfo))
                return
            }

            guard let result = result, let code = result["code"] as? Int else {
                let errorMsg = "requestAppReview internal json error"
                context.apiTrace.error(errorMsg)
                let errorInfo = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage(errorMsg)
                callback(.failure(error: errorInfo))
                return
            }
            
            // code为0 说明请求成功
            guard code == 0 else {
                let errorMsg = "requestAppReview fail with code:\(code), msg:\(result["msg"] ?? "")"
                context.apiTrace.error(errorMsg)
                let errorInfo = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage(errorMsg)
                callback(.failure(error: errorInfo))
                return
            }

            guard let data = result["data"] as? [AnyHashable: Any],
                  let allow = data["allow"] as? Bool else {
                      let errorMsg = "data format error"
                      context.apiTrace.error(errorMsg)
                      let errorInfo = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                          .setMonitorMessage(errorMsg)
                      callback(.failure(error: errorInfo))
                      return
                  }
            // 判断 是否频繁调用
            if allow {
                // 打开AppLink
                self.openAppLink(context: context, callback: callback)
            } else {
                // 频繁调用
                let errorMsg = "request requestAppReview too frequent"
                context.apiTrace.error(errorMsg)
                let errorInfo = OpenAPIError(code: GetAppReviewErrorCode.tooFrequency)
                    .setMonitorMessage(errorMsg)
                callback(.failure(error: errorInfo))
            }
        }
        let ecosystemAppContext = AppReviewContext(appId: uniqueID.appID, trace: context.getTrace())
        AppReviewFrequencyInterface.appReviewFrequency(with: ecosystemAppContext, parameters: [:], completionHandler: completionHandler)
    }

    private func openAppLink(context: OpenAPIContext,
                             callback: @escaping(OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        // 获取 applink拼接参数
        guard let appLinkParams = self.getBuildAppLinkParams(context: context) else {
            let errorInfo = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("appReview can't show because appLinkParams is nil")
            callback(.failure(error: errorInfo))
            return
        }
        // 获取 NavigationController
        guard let from = self.getNavigationFrom(context: context) else {
            let errorInfo = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("appReview can't show because can not find navigation controller")
            callback(.failure(error: errorInfo))
            return
        }
        // 获取 appLink
        guard let url = appReviewManager.getAppReviewLink(appLinkParams: appLinkParams) else {
            let errorMsg = "build launch query failed!"
            context.apiTrace.error(errorMsg)
            let errorInfo = OpenAPIError(code: GetAppReviewErrorCode.reviewFail)
                .setMonitorMessage(errorMsg)
            callback(.failure(error: errorInfo))
            return
        }
        // 打开 评分小程序
        userResolver.navigator.push(url, from: from)
        callback(.success(data: nil))
    }
    
    /// 获取拼接appLink的参数
    private func getBuildAppLinkParams(context: OpenAPIContext) -> AppLinkParams? {
        if context.uniqueID?.appType == .gadget {
           return getMicroAppBuildAppLinkParams(context: context)
        }
        if context.uniqueID?.appType == .webApp {
            return getWebAppBuildAppLinkParams(context: context)
        }
        return nil
    }
    
    private func getNavigationFrom(context: OpenAPIContext) -> UINavigationController? {
        if context.uniqueID?.appType == .gadget {
            return OPNavigatorHelper.topmostNav(window: context.uniqueID?.window)
        }
        if context.uniqueID?.appType == .webApp {
            guard let webBrowser = context.controller as? WebBrowser else {
                context.apiTrace.error("getNavigationFrom fail, webBrowser is nil")
                return nil
            }
            return OPNavigatorHelper.topmostNav(window: webBrowser.nodeWindow)
        }
        return nil
    }
    
    private func getMicroAppBuildAppLinkParams(context: OpenAPIContext) -> AppLinkParams? {
        
        guard let gadgetContext = context.gadgetContext as? GadgetAPIContext,
              let authorization = gadgetContext.authorization else {
                  context.apiTrace.error("gadgetContext or authorization is nil")
                  return nil
              }
        guard let uniqueID = context.uniqueID else {
            context.apiTrace.error("appReview can't show because uniqueID isn't exist")
            return nil
        }
        guard let common = BDPCommonManager.shared()?.getCommonWith(uniqueID) else {
            context.apiTrace.error("appReview can't show because common isn't exist")
            return nil
        }
        
        let task = BDPTaskManager.shared().getTaskWith(uniqueID)
        let pagePath = task?.currentPage?.absoluteString ?? ""
        
        return AppLinkParams(appId: uniqueID.appID,
                             appIcon: authorization.source.icon,
                             appName: authorization.source.name,
                             appType: .gadget,
                             appVersion: authorization.source.version,
                             origSeneType: common.schema.scene,
                             pagePath: pagePath,
                             fromType: .api,
                             trace: context.apiTrace.traceId)
    }
    
    private func getWebAppBuildAppLinkParams(context: OpenAPIContext) -> AppLinkParams? {
        guard let gadgetContext = context.gadgetContext as? GadgetAPIContext,
              let authorization = gadgetContext.authorization else {
                  context.apiTrace.error("gadgetContext or authorization is nil")
                  return nil
              }
        guard let uniqueID = context.uniqueID else {
            context.apiTrace.error("appReview can't show because uniqueID isn't exist")
            return nil
        }
        guard let webBrowser = context.controller as? WebBrowser else {
            context.apiTrace.error("appReview can't show because webAppInfo is empty")
            return nil
        }
        
        return AppLinkParams(appId: uniqueID.appID,
                             appIcon: authorization.source.icon,
                             appName: authorization.source.name,
                             appType: .webapp,
                             appVersion: nil,
                             origSeneType: nil,
                             pagePath: webBrowser.webview.url?.absoluteString,
                             fromType: .api,
                             trace: context.apiTrace.traceId)
    }
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "requestAppReview", pluginType: Self.self,
                             resultType: OpenAPIBaseResult.self
        ) { (this, _, context, gadgetContext, callback) in
            
            this.requestAppReview(context: context, gadgetContext: gadgetContext, callback: callback)
        }
        
        registerInstanceAsyncHandler(for: "endAppReview", pluginType: Self.self,
                             paramsType: OpenAPIEndAppReviewParams.self,
                             resultType: OpenAPIBaseResult.self
        ) { (this, params, context, callback) in
            
            this.endAppReview(params: params, context: context, callback: callback)
        }
    }
}
