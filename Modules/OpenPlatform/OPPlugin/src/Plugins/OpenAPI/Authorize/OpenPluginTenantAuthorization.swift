//
//  OpenPluginTenantAuthorization.swift
//  OPPlugin
//
//  Created by yi on 2021/4/9.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import ECOProbe
import OPSDK
import ECOInfra
import LKCommonsLogging
import LarkContainer

/// ApplyAppScopeStatus接口status字段 表示租户权限申请状态
enum EMAApplyAppScopeStatusCode: Int {
    case unRequest = 0
    case requestNull = 10246
    case requestOverflow = 10247
    case requesting = 10248
    case unauthorizeSensitivePermission = 10250

}
/// GetTenantAppScopes 接口code 字段 表示接口错误码
enum EMAGetTenantAppScopesErrorCode: Int {
    case success = 0
    case internalError = 2200
    case notVisibe = 10228
    case notInstall = 10245
}

final class OpenPluginTenantAuthorization: OpenBasePlugin {

    func getTenantAppScopes(params: OpenAPIBaseParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIGetTenantAppScopesResult>) -> Void) {
        
        let uniqueID = gadgetContext.uniqueID
        context.apiTrace.info("getTenantAppScopes invoke app=\(uniqueID)")

        EMARequestUtil.fetchTenantAppScopes(by: uniqueID) { (result, response, error) in
            let logID = response?.allHeaderFields["x-tt-logid"] as? String ?? ""
            guard let result = result, error == nil else {
                context.apiTrace.error("getTenantAppScopes invoke fail app=\(uniqueID), error \(error)")
                // 原逻辑为 serverBizError, CommoneErrorCode 不应当包含 serverBizError（因为每个 API 场景含义不同）。
                // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                // 三端一致会统一 CommoneCode，根据原 outerMessage 此处统一替换为 unknown，但仍然保持原 outerMessage 不变。
                let apiError = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setMonitorMessage("server data error(logid:\(logID))")
                callback(.failure(error: apiError))
                return
            }
            
            let code = result["code"] as? Int ?? 0
            let msg = result["msg"] as? String ?? ""
            guard let responseCodeValue = result["code"] as? Int, let responseCode = EMAGetTenantAppScopesErrorCode(rawValue: responseCodeValue) else {
                context.apiTrace.error("getTenantAppScopes invoke fail app=\(uniqueID), error code illgel")
                // 原逻辑为 serverBizError, CommoneErrorCode 不应当包含 serverBizError（因为每个 API 场景含义不同）。
                // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                // 三端一致会统一 CommoneCode，根据原 outerMessage 此处统一替换为 unknown，但仍然保持原 outerMessage 不变。
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setMonitorMessage("server biz error(logid:\(logID), code:\(code), msg:\(msg))")
                callback(.failure(error: error))
                return
            }
            if responseCode == .success {
                if let data = result["data"] as? [AnyHashable: Any], let scopes = data["scopes"] as? [Any]  {
                    var responseScopes: [Any] = []
                    for (i, scopeModel) in scopes.enumerated() {
                        if let scopeModel = scopeModel as? [AnyHashable: Any] {
                            let name = scopeModel["name"]
                            let status = scopeModel["status"]
                            var scope = [AnyHashable: Any]()
                            scope["name"] = name
                            scope["status"] = status
                            responseScopes.append(scope)
                        }
                    }
                    callback(.success(data: OpenAPIGetTenantAppScopesResult(scopes: responseScopes)))
                } else {
                    context.apiTrace.error("getTenantAppScopes invoke fetchTenantAppScopes fail app=\(uniqueID) error data is nil")
                    // 原逻辑为 serverBizError, CommoneErrorCode 不应当包含 serverBizError（因为每个 API 场景含义不同）。
                    // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                    // 三端一致会统一 CommoneCode，根据原 outerMessage 此处统一替换为 unknown，但仍然保持原 outerMessage 不变。
                    callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.unknown)))
                }

            } else {
                context.apiTrace.error("getTenantAppScopes invoke fetchTenantAppScopes fail app=\(uniqueID) errorCode \(responseCode)")
                switch responseCode {
                case .internalError:
                    // 原逻辑为 serverBizError, CommoneErrorCode 不应当包含 serverBizError（因为每个 API 场景含义不同）。
                    // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                    // 三端一致会统一 CommoneCode，根据原 outerMessage 此处统一替换为 unknown，但仍然保持原 outerMessage 不变。
                    callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.unknown).setMonitorMessage("server biz error(logid:\(logID), code:\(code), msg:\(msg))")))
                case .notVisibe:
                    let error = OpenAPIError(code: GetTenantAppScopesErrorCode.notVisible).setMonitorMessage("app is not visible").setOuterMessage("app is not visible(logid:\(logID)")
                    callback(.failure(error: error))
                case .notInstall:
                    let error = OpenAPIError(code: GetTenantAppScopesErrorCode.notInstalled).setMonitorMessage("app is not installed").setOuterMessage("app is not installed(logid:\(logID)")
                    callback(.failure(error: error))
                default:
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError).setMonitorMessage("unknown error").setOuterMessage("unknown error(logid:\(logID), code:\(code), msg:\(msg))")
                    callback(.failure(error: error))
                }
            }
        }
    }

    func applyTenantAppScope(params: OpenAPIBaseParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIApplyTenantAppScopeResult>) -> Void) {
        
        guard let controller = gadgetContext.getControllerElseFailure(context.apiTrace, callback) else {
            return
        }

        let uniqueID = gadgetContext.uniqueID
        context.apiTrace.info("applyTenantAppScope invoke app=\(uniqueID)")

        EMARequestUtil.fetchApplyAppScopeStatus(by: uniqueID) { (result, error) in
            guard let result = result, error == nil else {
                context.apiTrace.error("applyTenantAppScope invoke fetchApplyAppScopeStatus fail app=\(uniqueID), error \(error)")
                // 原逻辑为 serverBizError, CommoneErrorCode 不应当包含 serverBizError（因为每个 API 场景含义不同）。
                // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                // 三端一致会统一 CommoneCode，根据原 outerMessage 此处统一替换为 unknown，但仍然保持原 outerMessage 不变。
                callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.unknown)))
                return
            }
            guard let responseCodeValue = result["code"] as? Int, let responseCode = EMAGetTenantAppScopesErrorCode(rawValue: responseCodeValue) else {
                context.apiTrace.error("applyTenantAppScope invoke fetchApplyAppScopeStatus fail app=\(uniqueID), error code illgel")
                // 原逻辑为 serverBizError, CommoneErrorCode 不应当包含 serverBizError（因为每个 API 场景含义不同）。
                // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                // 三端一致会统一 CommoneCode，根据原 outerMessage 此处统一替换为 unknown，但仍然保持原 outerMessage 不变。
                callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.unknown)))
                return
            }
            if responseCode != .success {
                context.apiTrace.error("applyTenantAppScope invoke fetchApplyAppScopeStatus fail app=\(uniqueID), errorCode \(responseCode)")
                // 原逻辑为 serverBizError, CommoneErrorCode 不应当包含 serverBizError（因为每个 API 场景含义不同）。
                // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                // 三端一致会统一 CommoneCode，根据原 outerMessage 此处统一替换为 unknown，但仍然保持原 outerMessage 不变。
                callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.unknown)))
                return
            }
            guard let data = result["data"] as? [AnyHashable: Any], let statusValue = data["status"] as? Int, let status = EMAApplyAppScopeStatusCode(rawValue: statusValue) else {
                context.apiTrace.error("applyTenantAppScope invoke fetchApplyAppScopeStatus fail app=\(uniqueID), error data is nil")
                // 原逻辑为 serverBizError, CommoneErrorCode 不应当包含 serverBizError（因为每个 API 场景含义不同）。
                // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                // 三端一致会统一 CommoneCode，根据原 outerMessage 此处统一替换为 unknown，但仍然保持原 outerMessage 不变。
                callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.unknown)))
                return
            }
            var trackerType = ""
            if Self.isValidApplyAppScopeStatusCode(code: status) {
                var trackerParams = [AnyHashable: Any]()
                trackerType = Self.applyAppScopeStatusCodeToTrackerParam(code: status)
                trackerParams["type"] = trackerType
                BDPTracker.event("api_authrequest_request", attributes: trackerParams, uniqueID: uniqueID)
            }
            switch status {
            case .unRequest:
                EMALarkAlert.showAlert(title: BundleI18n.OPPlugin.OpenPlatform_gadgetRequestTitle, content: BundleI18n.OPPlugin.OpenPlatform_gadgetRequestContent, confirm: BundleI18n.OPPlugin.OpenPlatform_gadgetRequestApply, fromController: controller, numberOfLines: 0) {
                    var trackerParams = [AnyHashable: Any]()
                    trackerParams["action_type"] = "apply"
                    trackerParams["type"] = trackerType
                    BDPTracker.event("api_authrequest_sendrequest", attributes: trackerParams, uniqueID: uniqueID)
                    EMARequestUtil.requestApplyAppScope(by: uniqueID) { (result, error) in
                        guard let result = result, error == nil else {
                            TMACustomHelper.showCustomToast(BundleI18n.OPPlugin.OpenPlatform_gadgetRequest_SendFailedToast, icon: "", window: uniqueID.window)
                            context.apiTrace.error("applyTenantAppScope invoke requestApplyAppScope fail app=\(uniqueID), error \(error)")
                            // 原逻辑为 serverBizError, CommoneErrorCode 不应当包含 serverBizError（因为每个 API 场景含义不同）。
                            // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                            // 三端一致会统一 CommoneCode，根据原 outerMessage 此处统一替换为 unknown，但仍然保持原 outerMessage 不变。
                            callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.unknown)))
                            return
                        }
                        guard let responseCode = result["code"] as? Int else {
                            TMACustomHelper.showCustomToast(BundleI18n.OPPlugin.OpenPlatform_gadgetRequest_SendFailedToast, icon: "", window: uniqueID.window)
                            context.apiTrace.error("applyTenantAppScope invoke requestApplyAppScope fail app=\(uniqueID), error code illgel")
                            // 原逻辑为 serverBizError, CommoneErrorCode 不应当包含 serverBizError（因为每个 API 场景含义不同）。
                            // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                            // 三端一致会统一 CommoneCode，根据原 outerMessage 此处统一替换为 unknown，但仍然保持原 outerMessage 不变。
                            callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.unknown)))
                            return
                        }
                        if responseCode == 2200 {
                            TMACustomHelper.showCustomToast(BundleI18n.OPPlugin.OpenPlatform_gadgetRequest_SendFailedToast, icon: "", window: uniqueID.window)
                            context.apiTrace.error("applyTenantAppScope invoke requestApplyAppScope fail app=\(uniqueID), errorCode \(responseCode)")
                            // 原逻辑为 serverBizError, CommoneErrorCode 不应当包含 serverBizError（因为每个 API 场景含义不同）。
                            // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                            // 三端一致会统一 CommoneCode，根据原 outerMessage 此处统一替换为 unknown，但仍然保持原 outerMessage 不变。
                            callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.unknown)))
                        }
                        TMACustomHelper.showCustomToast(BundleI18n.OPPlugin.OpenPlatform_gadgetRequestApplyToast, icon: "success", window: uniqueID.window)
                        callback(.success(data: OpenAPIApplyTenantAppScopeResult(data: ["status": 1, "msg": "user agrees to apply"])))
                    }
                } cancelCallback: {
                    var trackerParams = [AnyHashable: Any]()
                    trackerParams["action_type"] = "cancel"
                    trackerParams["type"] = trackerType
                    BDPTracker.event("api_authrequest_sendrequest", attributes: trackerParams, uniqueID: uniqueID)
                    callback(.success(data: OpenAPIApplyTenantAppScopeResult(data: ["status": 2, "msg": "user cancels application"])))
                }
            case .requesting:
                EMALarkAlert.showAlert(title: BundleI18n.OPPlugin.OpenPlatform_gadgetRequest_repeatApplication, content: BundleI18n.OPPlugin.OpenPlatform_gadgetRequest_remindContent, confirm:  BundleI18n.OPPlugin.OpenPlatform_AppCenter_IKnow, fromController: controller, numberOfLines: 0, confirmCallback:  {
                    var trackerParams = [AnyHashable: Any]()
                    trackerParams["action_type"] = "no_operation"
                    trackerParams["type"] = trackerType
                    BDPTracker.event("api_authrequest_sendrequest", attributes: trackerParams, uniqueID: uniqueID)
                    callback(.success(data: OpenAPIApplyTenantAppScopeResult(data: ["status": 3, "msg": "administrator is processing"])))
                }, cancelCallback: nil)

            case .requestNull:
                EMALarkAlert.showAlert(title: BundleI18n.OPPlugin.OpenPlatform_gadgetRequest_allPermittedTitle, content: "", confirm:  BundleI18n.OPPlugin.OpenPlatform_AppCenter_IKnow, fromController: controller, numberOfLines: 0, confirmCallback: {
                    var trackerParams = [AnyHashable: Any]()
                    trackerParams["action_type"] = "no_operation"
                    trackerParams["type"] = trackerType
                    BDPTracker.event("api_authrequest_sendrequest", attributes: trackerParams, uniqueID: uniqueID)
                    callback(.success(data: OpenAPIApplyTenantAppScopeResult(data: ["status": 4, "msg": "administrator is processing"])))
                }, cancelCallback: nil)
            case .requestOverflow:
                EMALarkAlert.showAlert(title: BundleI18n.OPPlugin.OpenPlatform_gadgetRequest_exceedLimitTitle, content: BundleI18n.OPPlugin.OpenPlatform_gadgetRequest_remindContent, confirm:  BundleI18n.OPPlugin.OpenPlatform_AppCenter_IKnow, fromController: controller, numberOfLines: 0, confirmCallback: {
                    var trackerParams = [AnyHashable: Any]()
                    trackerParams["action_type"] = "no_operation"
                    trackerParams["type"] = trackerType
                    BDPTracker.event("api_authrequest_sendrequest", attributes: trackerParams, uniqueID: uniqueID)
                    callback(.success(data: OpenAPIApplyTenantAppScopeResult(data: ["status": 5, "msg": "the number of applications exceeds the limit"])))
                }, cancelCallback: nil)
            case .unauthorizeSensitivePermission:
                EMALarkAlert.showAlert(title: BundleI18n.OPPlugin.OpenPlatform_gadgetRequestTitle, content: "", confirm:  BundleI18n.OPPlugin.OpenPlatform_AppCenter_IKnow, fromController: controller, numberOfLines: 0, confirmCallback: {
                    var trackerParams = [AnyHashable: Any]()
                    trackerParams["action_type"] = "no_operation"
                    trackerParams["type"] = trackerType
                    BDPTracker.event("api_authrequest_sendrequest", attributes: trackerParams, uniqueID: uniqueID)
                    callback(.success(data: OpenAPIApplyTenantAppScopeResult(data: ["status": 6, "msg": "permission is not within the scope of application"])))
                }, cancelCallback: nil)
            default:
                callback(.success(data: nil))
            }
        }

    }

    class func isValidApplyAppScopeStatusCode(code: EMAApplyAppScopeStatusCode) -> Bool {
        if code == .unRequest || code == .requestNull || code == .requestOverflow || code == .requesting || code == .unauthorizeSensitivePermission {
            return true
        }
        return false
    }

    class func applyAppScopeStatusCodeToTrackerParam(code: EMAApplyAppScopeStatusCode) -> String {
        switch code {
        case .unRequest:
            return "normal_apply"
        case .requestNull:
            return "granted"
        case .requestOverflow:
            return "exceeds_limit"
        case .requesting:
            return "repeat_apply"
        case .unauthorizeSensitivePermission:
            return "unauthorize_sensitive_permission"
        default:
            return ""
        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "getTenantAppScopes", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenAPIGetTenantAppScopesResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.getTenantAppScopes(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: "applyTenantAppScope", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenAPIApplyTenantAppScopeResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.applyTenantAppScope(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}
