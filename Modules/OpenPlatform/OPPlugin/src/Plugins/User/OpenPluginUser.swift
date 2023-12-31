//
//  OpenPluginUser.swift
//  OPPlugin
//
//  Created by liuchong on 2021/4/14.
//

import Foundation
import LarkUIKit
import LarkOpenPluginManager
import OPPluginBiz
import OPFoundation
import LarkOpenAPIModel
import OPPluginManagerAdapter
import ECOInfra
import LarkAccountInterface
import LarkContainer
import LarkSetting

private struct OpenPluginGetUserCustomAttrSetting: SettingDecodable {
    static var settingKey = UserSettingKey.make(userKeyLiteral: "get_user_custom_attr_config")
    let appids: [String]
}

final class OpenPluginUser: OpenBasePlugin {
    
    private lazy var getUserCustomAttrSetting: OpenPluginGetUserCustomAttrSetting = {
        (try? userResolver.settings.setting(with: OpenPluginGetUserCustomAttrSetting.self)) ?? OpenPluginGetUserCustomAttrSetting(appids: [])
    }()

    @ScopedProvider var userService: PassportUserService?

    @ScopedProvider var openApiService: LarkOpenAPIService?
    
    lazy var apiUniteOpt: Bool = {
        userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.open.interface.api.unite.opt")
    }()
    
    var removeLarkSessionFromReqBody: Bool {
        return userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.network.remove_larksession_from_req_body")
    }
    
    @RealTimeFeatureGatingProvider(key: "openplatform.api.incremental_auth") var authCodeUnify: Bool
    
    public func getUserInfo(params: OpenPluginUserGetUserInfoParams, context:OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginUserGetUserInfoResult>) -> Void) {
        context.apiTrace.info("begin getUserInfo api")
        guard let userPlugin = BDPTimorClient.shared().userPlugin.sharedPlugin() as? BDPUserPluginDelegate else {
            context.apiTrace.error("userPlugin is nil")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("userPlugin is nil")
            callback(.failure(error: error))
            return
        }
        let credentials = params.credentials
        let uniqueID = gadgetContext.uniqueID
        BDPTracker.beginEvent("mp_get_user_info", primaryKey: BDPTrackerPKUserInfo, attributes: nil, uniqueID: uniqueID)
        guard userPlugin.bdp_isLogin() else {
            context.apiTrace.info("unlogin")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setOuterMessage("unlogin")
            callback(.failure(error: error))
            return
        }
        let session = gadgetContext.session
        guard !session.isEmpty else {
            context.apiTrace.error("Invalid Session.")
            let error = OpenAPIError(code: GetUserInfoErrorCode.invalidSession)
                .setOuterMessage("Invalid Session.")
                .setErrno(OpenAPIGetUserInfoErrno.invalidSession)
            callback(.failure(error: error))
            return
        }
        var headerFieldDict:[String:String] = ["User-Agent": BDPUserAgent.getString()]
        headerFieldDict.merge(GadgetSessionFactory.storage(for: gadgetContext).sessionHeader) {$1}
        let requestParams = [
            "appid":uniqueID.appID,
            "session": session,
            "withCredentials": credentials ? "true" : "false"
        ]
        fetchUserInfo(
            requestParams: requestParams,
            headerFieldDict: headerFieldDict,
            uniqueID: uniqueID,
            context: context,
            userPlugin: userPlugin) { (info, error, errMsg) in
            context.apiTrace.info("end fetchUserInfo")
            guard error == nil else {
                context.apiTrace.info("request error callback:\(String(describing: error))")
                // 原逻辑为 networkError, CommoneErrorCode 不应当包含 networkError（因为每个 API 场景含义不同）。
                // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                // 三端一致会统一 CommoneCode，此处统一替换为 internalError，但仍然保持原 outerMessage 不变。
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setOuterMessage("request error:\(String(describing: error))")
                if let monitorMsg = errMsg {
                    error.setMonitorMessage(monitorMsg)
                }
                callback(.failure(error: error))
                return
            }
            guard let userInfo = info else {
                context.apiTrace.info("response info is nil")
                let error = OpenAPIError(code: GetUserInfoErrorCode.getUserInfoFail)
                    .setOuterMessage("response info is nil")
                    .setErrno(OpenAPIGetUserInfoErrno.getUserInfoFailed)
                if let monitorMsg = errMsg {
                    error.setMonitorMessage(monitorMsg)
                }
                callback(.failure(error: error))
                return
            }
            callback(.success(data: OpenPluginUserGetUserInfoResult(data: userInfo)))
            BDPTracker.event("mp_get_user_info_result", attributes: nil, uniqueID: uniqueID)
            context.apiTrace.info("end getUserInfo api")
        }
    }

    func fetchUserInfo(
        requestParams: [String: String],
        headerFieldDict: [String: String],
        uniqueID: OPAppUniqueID,
        context:OpenAPIContext,
        userPlugin: BDPUserPluginDelegate,
        complete: @escaping (Dictionary<String,Any>?, Error?, String?) -> Void
    ) {
        func handleResult(
            jsonObj: Any?,
            logID: String,
            taskError: Error?) {
                let trace = BDPTracingManager.sharedInstance().getTracingBy(uniqueID)
                let monitor = OPMonitor(kEventName_mp_user_info_result).setUniqueID(uniqueID).tracing(trace).timing()
                guard taskError == nil else {
                    monitor.addCategoryValue(kEventKey_result_type, kEventValue_fail).setError(taskError).flush()
                    context.apiTrace.error("request error :\(String(describing: taskError))")
                    complete(nil, taskError, "task error(logid:\(logID))")
                    return
                }
                guard jsonObj != nil else {
                    monitor.addCategoryValue(kEventKey_result_type, kEventValue_fail).addCategoryValue(kEventKey_error_msg, "Response Data Error").flush()
                    context.apiTrace.error("request result is nil")
                    complete(nil, taskError, "json nil(logid:\(logID))")
                    return
                }
                var result = jsonObj as? [String: Any] ?? [:]
                let code = result["error"] as? Int ?? 0
                let msg = result["message"] as? String ?? ""
                guard code == 0 else {
                    context.apiTrace.error("request result code : \(code)")
                    complete(nil, taskError, "server biz error(logid:\(logID), code:\(code), msg:\(msg)")
                    return
                }
                context.apiTrace.info("request result success!)")
                if let data = result["data"] as? [String:Any] ?? nil {
                    result = data
                }
                if BDPType.webApp != uniqueID.appType, let commonManager = BDPCommonManager.shared(), let common = commonManager.getCommonWith(uniqueID), common.model.authList.contains("getUserInfo") {
                    var mutableUserInfo = result["userInfo"] as? [String:Any] ?? [String:Any]()
                    mutableUserInfo["userId"] = userPlugin.bdp_userId()
                    mutableUserInfo["sessionId"] = userPlugin.bdp_sessionId()
                    var mResult = result
                    mResult["userInfo"] = mutableUserInfo
                    complete(mResult, nil, nil)
                }else {
                    context.apiTrace.info("apptype:\(uniqueID.appType),commonmanager:\(BDPCommonManager.shared() == nil), common: \(BDPCommonManager.shared()?.getCommonWith(uniqueID))")
                    complete(result, nil, nil)
                }
                BDPTracker.endEvent("mp_login_result", primaryKey: BDPTrackerPKLogin, attributes: nil, uniqueID: uniqueID)
                monitor.addCategoryValue(kEventKey_result_type, kEventValue_success).timing().addCategoryValue(kEventKey_error_code, result["error"]).addCategoryValue(kEventKey_error_msg, result["message"]).flush()
        }
        
        let url = BDPType.webApp == uniqueID.appType ? EMAAPI.userInfoH5URL() : EMAAPI.userInfoURL()
        let path = BDPType.webApp == uniqueID.appType ? OPNetworkAPIPath.webAppGetUserInfo : OPNetworkAPIPath.getUserInfo
        context.apiTrace.info("begin fetchUserInfo")
        if OPECONetworkInterface.enableECO(path: path) {
            OPECONetworkInterface.postForOpenDomain(url: url,
                                       context: OpenECONetworkAppContext(trace: context.apiTrace, uniqueId: uniqueID, source: .api),
                                       params: requestParams,
                                       header: headerFieldDict) { json, _, response, error in
                let logID = response?.allHeaderFields["x-tt-logid"] as? String ?? ""
                handleResult(jsonObj: json, logID: logID, taskError: error)
            }
        } else {
            let eventName = "getUserInfo"
            context.apiTrace.info("\(eventName):\(String(describing: url))")
            let config = BDPNetworkRequestExtraConfiguration.defaultConfig()
            config?.method = .POST
            if let config = config {
                config.bdpRequestHeaderField = headerFieldDict as [AnyHashable : Any]
            } else {
                context.apiTrace.info("config is nil")
            }
            context.apiTrace.info("begin fetchUserInfo")
            BDPNetworking.task(withRequestUrl: url, parameters: requestParams, extraConfig: config) { (taskError, jsonObj, response) in
                let logID = response?.allHeaderFields["x-tt-logid"] as? String ?? ""
                handleResult(jsonObj: jsonObj, logID: logID, taskError: taskError)
            }
        }
    }
    
    public func getUserInfoEx(params: OpenAPIBaseParams, context:OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginGetUserInfoExResult>) -> Void) {
        context.apiTrace.info("begin getUserInfoEx api")
        let uniqueID = gadgetContext.uniqueID
        
        if self.apiUniteOpt {
            guard let openApiService = self.openApiService else {
                context.apiTrace.error("openApiService is nil")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("openApiService is nil")
                callback(.failure(error: error))
                return
            }
            openApiService.getUserInfoEx { (info) in
                context.apiTrace.info("getUserInfoEx success, app:\(uniqueID)")
                callback(.success(data: OpenPluginGetUserInfoExResult(data: info ?? [:])))
            } failBlock: {
                context.apiTrace.error("getUserInfoEx fail, app:\(uniqueID)")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("getUserInfoEx fail, app:\(uniqueID)")
                callback(.failure(error: error))
            }
        } else {
            guard let delegate = EMAProtocolProvider.getEMADelegate() else {
                context.apiTrace.error("getUserInfoEx delegate is nil")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("getUserInfoEx delegate is nil")
                callback(.failure(error: error))
                return
            }
            delegate.getUserInfoExSuccess { (info) in
                context.apiTrace.info("getUserInfoEx success, app:\(uniqueID)")
                callback(.success(data: OpenPluginGetUserInfoExResult(data: info ?? [:])))
            } fail: {
                context.apiTrace.error("getUserInfoEx fail, app:\(uniqueID)")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("getUserInfoEx fail, app:\(uniqueID)")
                callback(.failure(error: error))
            }
        }
    }

    func getUserCustomAttr(params: OpenAPIBaseParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginGetUserCustomAttrResponse>) -> Void) {
        guard getUserCustomAttrSetting.appids.contains(gadgetContext.uniqueID.appID) else {
            context.apiTrace.error("getUserCustomAttr not organizationAuth")
            let error = OpenAPIError(errno: OpenAPICommonErrno.organizationAuthDeny)
            return callback(.failure(error: error))
        }
        
        guard let userService else {
            let error = OpenAPIError(errno: OpenAPICommonErrno.internalError).setMonitorMessage("resolve PassportUserService failed")
            return callback(.failure(error: error))
        }
            
        let userCustomAttr = userService.user.userCustomAttrMap
        let response = OpenPluginGetUserCustomAttrResponse(userCustomAttr: userCustomAttr)
        callback(.success(data: response))
    }
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "tma_login", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenPluginUserLoginResult.self) { (this, params, context, gadgetContext, callback) in
            this.login(params: params, context:context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: "login", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenPluginUserLoginResult.self) { (this, params, context, gadgetContext, callback) in
            this.login(params: params, context:context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: "getUserInfo", pluginType: Self.self, paramsType: OpenPluginUserGetUserInfoParams.self, resultType: OpenPluginUserGetUserInfoResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.getUserInfo(params: params, context:context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: "getUserInfoEx", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenPluginGetUserInfoExResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.getUserInfoEx(params: params, context:context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: "getUserCustomAttr", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenPluginGetUserCustomAttrResponse.self) { (this, params, context, gadgetContext, callback) in
            context.apiTrace.info("getUserCustomAttr API call start")
            this.getUserCustomAttr(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            context.apiTrace.info("getUserCustomAttr API call end")
        }
    }
}
