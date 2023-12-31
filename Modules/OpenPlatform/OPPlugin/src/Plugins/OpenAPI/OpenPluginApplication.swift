//
//  OpenPluginApplication.swift
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
import LKCommonsLogging
import LarkLocalizations
import LarkAccountInterface
import LarkSetting
import WebBrowser
import LarkContainer

public class OpenPluginApplication: OpenBasePlugin {
    
    @ScopedProvider private var userService: PassportUserService?

    func getLaunchOptionsSync(context: OpenAPIContext, gadgetContext: GadgetAPIContext)-> OpenAPIBaseResponse<OpenAPIGetLaunchOptionsResult> {
        
        let uniqueID = gadgetContext.uniqueID

        guard let common = BDPCommonManager.shared()?.getCommonWith(uniqueID), let coldBootSchema = common.coldBootSchema else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("common is nil").setErrno(OpenAPICommonErrno.internalError)
            return .failure(error: error)
        }
        var launchParams = BDPApplicationManager.getLaunchOptionParams(coldBootSchema, type: uniqueID.appType)
        context.apiTrace.info("getLaunchOptions launchParams:\(launchParams)")
        if uniqueID.appType == .gadget {
            let task = BDPTaskManager.shared()?.getTaskWith(uniqueID)

            let launchPath = launchParams["path"] as? String
            let launchPathIsEmpty = launchPath?.isEmpty ?? true
            if launchPathIsEmpty {
                launchParams["path"] = task?.config?.entryPagePath
                launchParams["query"] = ""
            }

        } else {
            context.apiTrace.info("not native app")
        }
        let result = OpenAPIGetLaunchOptionsResult(data: launchParams)
        return .success(data: result)
    }

    func getHostLaunchQuerySync(context: OpenAPIContext, gadgetContext: GadgetAPIContext)-> OpenAPIBaseResponse<OpenAPIGetHostLaunchQueryResult> {
        
        let uniqueID = gadgetContext.uniqueID
        let common = BDPCommonManager.shared()?.getCommonWith(uniqueID)
        let launchQuery = common?.schema.originQueryParams?["bdp_launch_query"] as? String ?? ""
        context.apiTrace.info("launchQuery:\(launchQuery)")
        let result = OpenAPIGetHostLaunchQueryResult(launchQuery: launchQuery)
        return .success(data: result)
    }

    func getHostLaunchQuery(context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIGetHostLaunchQueryResult>) -> Void) {
        callback(getHostLaunchQuerySync(context: context, gadgetContext: gadgetContext))
    }

    func getAppInfoSync(context: OpenAPIContext, gadgetContext: GadgetAPIContext) -> OpenAPIBaseResponse<OpenAPIGetAppInfoSyncResult> {
        
        let uniqueID = gadgetContext.uniqueID
        let schemaString:String
        let appId:String
        let session:String
        let whiteList:[String]
        let blackList:[String]
        if let commonManager = BDPCommonManager.shared(),  let common = commonManager.getCommonWith(uniqueID) {
            // 小程序收银台相关参数
            if let originURL = common.schema.originURL {
                schemaString = originURL.absoluteString // 当前使用的schema
            } else {
                schemaString = ""
                context.apiTrace.info("originURL is nil")
            }
            appId = common.uniqueID.appID
            session = gadgetContext.session
            whiteList = common.model.authList
            blackList = common.model.blackList
        } else {
            context.apiTrace.info("commonManager is nil? \(BDPCommonManager.shared() == nil)")
            session = gadgetContext.session
            appId = uniqueID.appID
            schemaString = ""
            whiteList = []
            blackList = []
        }
        let result = OpenAPIGetAppInfoSyncResult(appId: appId, session: session, schema: schemaString, whiteList: whiteList, blackList: blackList)
        return .success(data: result)
    }

    func getAppbrandSettingsSync(params: OpenAPIGetAppbrandSettingsParams, context: OpenAPIContext) -> OpenAPIBaseResponse<OpenAPIGetAppbrandSettingsResult> {
        /**
         提供一个接口给到前端，用于获取小程序setting配置信息
         文档：https://bytedance.feishu.cn/space/doc/doccnPkSqgLGp4kOFQCYN4WDsrb
        */
        let key = params.fields.joined(separator: ".")
        let result = BDPSettingsManager.shared().s_dictionaryValue(forKey: key)
        if !result.isEmpty {
            if let jsonData = try? JSONSerialization.data(withJSONObject: result) {
                if let jsonString = String(data: jsonData, encoding: .utf8), !jsonString.isEmpty {
                    return .success(data: OpenAPIGetAppbrandSettingsResult(data: jsonString))
                }
            }
        }
        let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
            .setMonitorMessage("gadgetContext is nil").setOuterMessage("no settings data in fields")
        return .failure(error: error)
    }

    func snapshotReady(context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        
        let uniqueID = gadgetContext.uniqueID

        let common = BDPCommonManager.shared()?.getCommonWith(uniqueID)
        common?.isSnapshotReady = true
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "kBDPSnapshotRenderReadyNotification"), object: nil)
        callback(.success(data: nil))
    }
    
    func setMenuButtonVisibility(params: OpenAPIMenuButtonAbilityParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        
        let uniqueID = gadgetContext.uniqueID
 
        guard let common = BDPCommonManager.shared()?.getCommonWith(uniqueID) else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("common is nil").setErrno(OpenAPICommonErrno.internalError)
            return callback(.failure(error: error))
        }
        if common.model.authList.contains("setMenuButtonVisibility") {
            let visible = params.visible
            let task = BDPTaskManager.shared()?.getTaskWith(uniqueID)
            task?.toolBarManager?.hidden = !visible
            context.apiTrace.info("set menu button visibility success, app=\(uniqueID), visible=\(visible)")
            callback(.success(data: nil))
        } else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("setMenuButtonVisibility permission denied").setOuterMessage("permission denied").setErrno(OpenAPICommonErrno.authenFail)
            return callback(.failure(error: error))
        }
    }
    
    func showMorePanel(context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        
        let uniqueID = gadgetContext.uniqueID

        guard let common = BDPCommonManager.shared()?.getCommonWith(uniqueID)  else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("common is nil").setErrno(OpenAPICommonErrno.internalError)
            return callback(.failure(error: error))
        }
        
        guard let model = OPUnsafeObject(common.model) else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("model is nil").setErrno(OpenAPICommonErrno.internalError)
            return callback(.failure(error: error))
        }
        
        guard let _ = OPUnsafeObject(model.authList) else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("authList is nill").setErrno(OpenAPICommonErrno.internalError)
            return callback(.failure(error: error))
        }
        
        guard let _ = OPUnsafeObject(model.webURL) else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("webURL is nil").setErrno(OpenAPICommonErrno.internalError)
            return callback(.failure(error: error))
        }
        
        if model.authList.contains("showMorePanel") || !model.webURL.isEmpty {
            BDPMorePanelManager.openMorePanel(with: uniqueID)
            context.apiTrace.info("show more panel success, app=\(uniqueID)")
            callback(.success(data: nil))
       } else {
           let monitorMessage = model.webURL.isEmpty ? "webURL is empty" : "showMorePanel permission denied"
           let outerMessage = model.webURL.isEmpty ? "url empty" : "permission denied"
           let errno = model.webURL.isEmpty ? OpenAPICommonErrno.unknown : OpenAPICommonErrno.authenFail
           let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
               .setMonitorMessage(monitorMessage).setOuterMessage(outerMessage).setErrno(errno)
           return callback(.failure(error: error))
       }
    }
    
    func enableLeaveConfirm(params: OpenAPIEnableLeaveConfirmParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        if !userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.web.leaveconfirm.disable"), context.uniqueID?.appType == .webApp {
            guard let browser = gadgetContext.controller as? WebBrowser else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("apiContext.controller is not WebBrowser")
                context.apiTrace.error("apiContext.controller is not WebBrowser")
                return callback(.failure(error: error))
            }
            
            guard let extensionItem = browser.resolve(LeaveConfirmExtensionItem.self) else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("extension is not registed")
                context.apiTrace.error("extension is not registed")
                return callback(.failure(error: error))
            }
            
            if let error = OpenPluginApplication.trySetWebLeaveConfirm(extensionItem: extensionItem, params: params) {
                return callback(.failure(error: error))
            }
        } else {
            guard let currentController = gadgetContext.controller as? BDPAppController else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("controller is nil").setErrno(OpenAPICommonErrno.internalError)
                return callback(.failure(error: error))
            }
            
            guard let currentPageController = currentController.currentAppPage() else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("page is nil").setErrno(OpenAPICommonErrno.internalError)
                return callback(.failure(error: error))
            }
            
            // 入参校验
            if let error = params.checkError() {
                return callback(.failure(error: error))
            }
            
            let confirmText = params.confirmText.count > 0 ? params.confirmText : BundleI18n.OPPlugin.determine
            let cancelText = params.cancelText.count > 0 ? params.cancelText : BundleI18n.OPPlugin.cancel
            
            currentPageController.addLeaveComfirmTitle(params.title, content: params.content, confirmText: confirmText, cancelText: cancelText, effect: params.effect, confirmColor: params.confirmColor, cancelColor: params.confirmText)
        }
        callback(.success(data: nil))
    }
    
    func disableLeaveConfirm(context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        if !userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.web.leaveconfirm.disable"), context.uniqueID?.appType == .webApp {
            guard let browser = gadgetContext.controller as? WebBrowser else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("apiContext.controller is not WebBrowser")
                context.apiTrace.error("apiContext.controller is not WebBrowser")
                callback(.failure(error: error))
                return
            }
            
            guard let extensionItem = browser.resolve(LeaveConfirmExtensionItem.self) else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("extension is not registed")
                context.apiTrace.error("extension is not registed")
                callback(.failure(error: error))
                return
            }
            
            extensionItem.leaveConfirm = nil
            
        } else {
            guard let currentController = gadgetContext.controller as? BDPAppController else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("controller is nil")
                    .setErrno(OpenAPICommonErrno.internalError)
                return callback(.failure(error: error))
            }
            
            guard let currentPageController = currentController.currentAppPage() else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("page is nil")
                    .setErrno(OpenAPICommonErrno.internalError)
                return callback(.failure(error: error))
            }
            currentPageController.cancelLeaveComfirm()
        }
        callback(.success(data: nil))
    }
    
    func onNavigateBack(context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        
        
        // 全量开关,如果打开，则不再校验权限
        if !FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: "openplatform.gadget.takeover.back.fullload")) {
            
            let uniqueID = gadgetContext.uniqueID
            
            guard let plugin = BDPTimorClient.shared().authorizationPlugin.sharedPlugin() as? BDPAuthorizationPluginDelegate, plugin.bpd_isApiAvailable("onNavigateBack", for: uniqueID) else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                    .setMonitorMessage("Unsupported API onNavigateBack").setErrno(OpenAPICommonErrno.unable)
                return callback(.failure(error: error))
            }
        }
        
        guard let currentController = gadgetContext.controller as? BDPAppController else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("controller is nil").setErrno(OpenAPICommonErrno.internalError)
            return callback(.failure(error: error))
        }
        
        guard let currentPageController = currentController.currentAppPage() else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("page is nil").setErrno(OpenAPICommonErrno.internalError)
            return callback(.failure(error: error))
        }
        currentPageController.takeoverBackEvent()
        callback(.success(data: nil))
    }
    
    func onExitMiniProgram(context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        
        let uniqueID = gadgetContext.uniqueID
        
        guard let plugin = BDPTimorClient.shared().authorizationPlugin.sharedPlugin() as? BDPAuthorizationPluginDelegate, plugin.bpd_isApiAvailable("onExitMiniProgram", for: uniqueID) else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                .setMonitorMessage("Unsupported API onExitMiniProgram")
                .setErrno(OpenAPICommonErrno.authenFail)
            return callback(.failure(error: error))
        }
        
        guard uniqueID.appType == .gadget else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("takeoverExitEvent failed, invalid host")
                .setErrno(OpenAPICommonErrno.internalError)
            return callback(.failure(error: error))
        }
        
        let task = BDPTaskManager.shared()?.getTaskWith(uniqueID)
        task?.takeoverExitEvent = true
        context.apiTrace.info("takeoverExitEvent success, app=\(uniqueID)")
        callback(.success(data: nil))
    }


    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceSyncHandlerGadget(for: "getLaunchOptionsSync", pluginType: Self.self, resultType: OpenAPIGetLaunchOptionsResult.self) { (this, _, context, gadgetContext) -> OpenAPIBaseResponse<OpenAPIGetLaunchOptionsResult> in
            
            return this.getLaunchOptionsSync(context: context, gadgetContext: gadgetContext)
        }
        registerInstanceAsyncHandlerGadget(for: "getHostLaunchQuery", pluginType: Self.self, resultType: OpenAPIGetHostLaunchQueryResult.self) { (this, _, context, gadgetContext, callback) in
            
            this.getHostLaunchQuery(context: context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceSyncHandlerGadget(for: "getHostLaunchQuerySync", pluginType: Self.self, resultType: OpenAPIGetHostLaunchQueryResult.self) { (this, _, context, gadgetContext) -> OpenAPIBaseResponse<OpenAPIGetHostLaunchQueryResult> in
            
            return this.getHostLaunchQuerySync(context: context, gadgetContext: gadgetContext)
        }
        registerInstanceSyncHandlerGadget(for: "getAppInfoSync", pluginType: Self.self, resultType: OpenAPIGetAppInfoSyncResult.self) { (this, params, context, gadgetContext) -> OpenAPIBaseResponse<OpenAPIGetAppInfoSyncResult> in
            
            return this.getAppInfoSync(context: context, gadgetContext: gadgetContext)
        }

        registerInstanceSyncHandler(for: "getAppbrandSettingsSync", pluginType: Self.self, paramsType: OpenAPIGetAppbrandSettingsParams.self, resultType: OpenAPIGetAppbrandSettingsResult.self) { (this, params, context) -> OpenAPIBaseResponse<OpenAPIGetAppbrandSettingsResult> in
            
            return this.getAppbrandSettingsSync(params: params, context: context)
        }

        registerInstanceAsyncHandlerGadget(for: "snapshotReady", pluginType: Self.self) { (this, _, context, gadgetContext, callback) in
            
            this.snapshotReady(context: context, gadgetContext: gadgetContext, callback: callback)
        }
        
        registerInstanceAsyncHandlerGadget(for: "setMenuButtonVisibility", pluginType: Self.self, paramsType: OpenAPIMenuButtonAbilityParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            return this.setMenuButtonVisibility(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        
        registerInstanceAsyncHandlerGadget(for: "showMorePanel", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenAPIBaseResult.self) { (this, _, context, gadgetContext, callback) in
            
            return this.showMorePanel(context: context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandler(for: "getUserInfoInJSWorker", resultType: OpenAPIGetUserInfoInJSWorkerResult.self) { this, _, _, callback in
            let uid = this.userResolver.userID
            DispatchQueue.global().async { [weak self] in
                guard let userService = self?.userService else {
                    callback(.failure(error: OpenAPIError(errno: OpenAPICommonErrno.internalError).setMonitorMessage("resolve PassportUserService failed")))
                    return
                }
                let avatarUrl = userService.user.avatarURL
                let localizedName = userService.user.localizedName
                if !uid.isEmpty {
                    callback(.success(data: OpenAPIGetUserInfoInJSWorkerResult(userId: uid, userName: localizedName, userAvatarUrl: avatarUrl)))
                } else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setMonitorMessage("userid is empty")
                    callback(.failure(error: error))
                }
            }
        }
        
        registerInstanceAsyncHandlerGadget(for: "enableLeaveConfirm", pluginType: Self.self, paramsType: OpenAPIEnableLeaveConfirmParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            return this.enableLeaveConfirm(params:params,context: context, gadgetContext: gadgetContext, callback: callback)
        }

        registerInstanceAsyncHandlerGadget(for: "disableLeaveConfirm", pluginType: Self.self, resultType: OpenAPIBaseResult.self) { (this, _, context, gadgetContext, callback) in
            
            
            return this.disableLeaveConfirm(context: context, gadgetContext: gadgetContext, callback: callback)
        }
        
        registerInstanceAsyncHandlerGadget(for: "onNavigateBack", pluginType: Self.self, resultType: OpenAPIBaseResult.self) { (this, _, context, gadgetContext, callback) in
            
            
            return this.onNavigateBack(context: context, gadgetContext: gadgetContext, callback: callback)
        }
        
        registerInstanceAsyncHandlerGadget(for: "onExitMiniProgram", pluginType: Self.self, resultType: OpenAPIBaseResult.self) { (this, _, context, gadgetContext, callback) in
            
            
            return this.onExitMiniProgram(context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}

extension OpenPluginApplication {
    
    /// 单独抽离函数用于 pageshow 场景设置 https://bytedance.feishu.cn/wiki/wikcnZ9aDLYZlnOIIgc729dbbLx
    public static func trySetWebLeaveConfirm(extensionItem: LeaveConfirmExtensionItem, params: OpenAPIEnableLeaveConfirmParams) -> OpenAPIError? {
        
        // 补充参数校验（用于pageshow直接调用场景）
        if let error = params.checkError() {
            return error
        }
        
        let confirmText = params.confirmText.count > 0 ? params.confirmText : BundleI18n.OPPlugin.determine
        let cancelText = params.cancelText.count > 0 ? params.cancelText : BundleI18n.OPPlugin.cancel
        
        let leaveConfirm = WebLeaveComfirmModel(
            title: params.title,
            content: params.content,
            confirmText: confirmText,
            cancelText: cancelText,
            effect: params.effect
        )
        
        extensionItem.leaveConfirm = leaveConfirm
        
        return nil
    }
}
