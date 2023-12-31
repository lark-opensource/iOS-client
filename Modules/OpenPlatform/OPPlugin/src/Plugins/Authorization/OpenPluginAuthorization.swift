//
//  OpenAuthorize.swift
//  OPPlugin
//
//  Created by laisanpin on 2021/5/7.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPSDK
import OPPluginManagerAdapter
import OPFoundation
import LarkContainer
import TTMicroApp

final class OpenPluginAuthorization: OpenBasePlugin {
    // MARK: Plugin Method
    func authorize(params: OpenAPIAuthorizationParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping(OpenAPIBaseResponse<OpenAPIAuthorizationResult>) -> Void) {

        let uniqueID = gadgetContext.uniqueID
        let scopeString = params.scope

        var trackerParams = [String:String]()
        trackerParams["authorize_scope"] = scopeString
        trackerParams["app_id"] = uniqueID.appID
        trackerParams["application_type"] = uniqueID.appType.applicationTypeString

        let appName = BDPCommonManager.shared()?.getCommonWith(uniqueID)?.model.name ?? ""
        trackerParams["appname"] = appName

        BDPTracker.event("api_invoke_authorize", attributes: trackerParams, uniqueID: uniqueID)
        let scopeList = scopeString.components(separatedBy: ",")
        let scopeListCount = scopeList.count

        guard let authorization = gadgetContext.authorization else {
            context.apiTrace.error("gadgetContext authorization is nil")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError).setMonitorMessage("gadgetContext authorization is nil")
            callback(.failure(error: error))
            return
        }
        
        guard let controller = gadgetContext.getControllerElseFailure(context.apiTrace, callback) else {
            return
        }

        // 请求单个权限
        if scopeListCount == 1 {
            guard let scope = scopeList.first, !scope.isEmpty else {
                context.apiTrace.error("scope is empty string")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam).setMonitorMessage("scope is empty string")
                callback(.failure(error: error))
                return
            }

            guard let innerScope = BDPAuthorization.transfromScope(toInnerScope: scope) else {
                context.apiTrace.error("scope trans to innerScope faild")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError).setMonitorMessage("scope trans to innerScope faild")
                callback(.failure(error: error))
                return
            }

            let provider = BDPAuthModuleControllerProvider()
            provider.controller = controller
            authorization.requestUserPermission(forScopeIfNeeded: innerScope, uniqueID: uniqueID, authProvider: authorization, delegate: provider) { [weak self] (result) in
                guard let `self` = self else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage("self is nil When call API")
                    callback(.failure(error: error))
                    context.apiTrace.error("self is nil When call authorize API")
                    return
                }

                //先埋点
                var trackerParams = [String:String]()
                trackerParams["application_type"] = uniqueID.appType.applicationTypeString
                trackerParams["authorize_status"] = result.authorizeStateString
                trackerParams["authorize_scope"] = scopeString
                trackerParams["appname"] = appName
                BDPTracker.event("api_authorize_callback", attributes: trackerParams, uniqueID: uniqueID)

                let data = [scope : result.matchRequestResultString]
                self.authorizeCallback(permissionResult: result, data: data, callback: callback)
            }

        } else if (scopeListCount > 1) {
            //判断scopeList中是否包含非法scope;
            let invalidScopes = getInvalidScopes(scopeList: scopeList)

            guard invalidScopes.isEmpty else {
                context.apiTrace.error("scopeList is invalid: \(invalidScopes)")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam).setOuterMessage(BDPAuthorizationPermissionResult.invalidScope.matchRequestResultString).setMonitorMessage("scopeList is invalid")
                callback(.failure(error: error))
                return
            }

            //白名单小程序，过滤不可聚合权限
            let hasNoncombineScope = hasNonCombineScope(scopeList: scopeList)
            guard !hasNoncombineScope else {
                context.apiTrace.error("scopeList contain nonCombine scope")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam).setMonitorMessage("scopeList contain nonCombine scope")
                callback(.failure(error: error))
                return
            }

            let provider = BDPAuthModuleControllerProvider()
            provider.controller = controller
            authorization.requestUserPermissionHybrid(forScopeList: scopeList, uniqueID: uniqueID, authProvider: authorization, delegate: provider) {(resultDic) in
                //先埋点
                var trackerParams = [String:String]()
                trackerParams["appname"] = appName
                trackerParams["app_id"] = uniqueID.appID
                trackerParams["application_type"] = uniqueID.appType.applicationTypeString
                trackerParams["authorize_scope"] = scopeString

                var authorizeStatusList = [String]()

                scopeList.forEach {
                    if let value = resultDic[$0] {
                        if value.uintValue == BDPAuthorizationPermissionResult.enabled.rawValue {
                            authorizeStatusList.append("approved")
                        } else {
                            authorizeStatusList.append("rejected")
                        }
                    } else {
                        authorizeStatusList.append("approved")
                    }
                }
                trackerParams["authorize_status"] = authorizeStatusList.joined(separator: ",")
                BDPTracker.event("api_authorize_callback", attributes: trackerParams, uniqueID: uniqueID)

                var data = [String:String]()

                ///TODO:原逻辑注释标明"多个权限请求中只要有一个失败则全部失败", 然后在遍历过程中有一个type变量, 但是这个变量并没有被使用;
                /**if (result != BDPAuthorizationPermissionResultEnabled) {
                 type = BDPJSBridgeCallBackTypeFailed;
                 }
                 */
                for (scopeString, result) in resultDic {
                    if let permissionResult = BDPAuthorizationPermissionResult(rawValue:result.uintValue) {
                        data[scopeString] = permissionResult.matchRequestResultString
                    } else {
                        data[scopeString] = "deny"
                    }
                }

                callback(.success(data: OpenAPIAuthorizationResult(data: data)))
            }
        } else {
            context.apiTrace.error("scopeList is empty")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam).setMonitorMessage("scopeList is empty")
            callback(.failure(error: error))
        }
    }

    // MARK: Private Method
    // 检查scopes组合是否合法
    // 不合法 - 不可聚合授权的scope的数量 > 1
    // 不合法 - 同时存在可聚合授权的scope和不可聚合授权的scope
    private func hasNonCombineScope(scopeList:[String]) -> Bool {
        if scopeList.count <= 1 {
            return false
        }

        for scope in scopeList {
            if scope == BDPScopeUserInfo || scope == BDPScopeAddress {
                return true
            }
        }
        return false
    }


    private func authorizeCallback(permissionResult: BDPAuthorizationPermissionResult, data: [String:String], callback: (OpenAPIBaseResponse<OpenAPIAuthorizationResult>) -> Void) {
        switch permissionResult {
        case .enabled:
            callback(.success(data: OpenAPIAuthorizationResult(data: data)))
        case .systemDisabled:
            callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny).setAddtionalInfo(["data": data])))
        case .userDisabled:
            callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.userAuthDeny).setAddtionalInfo(["data": data])))
        case .invalidScope:
            callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.invalidParam).setAddtionalInfo(["data": data])))
        case .platformDisabled:
            callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.invalidParam).setAddtionalInfo(["data": data])))
        default:
            callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.unknown).setAddtionalInfo(["data": data])))
        }
    }

    //获取非法的socpe数组
    private func getInvalidScopes(scopeList: [String]) -> [String] {
        var invalidSocpes = [String]()

        scopeList.forEach {
            if !isValidScope(scope: $0) {
                invalidSocpes.append($0)
            }
        }

        return invalidSocpes
    }
    //scope是否合法
    private func isValidScope(scope: String) -> Bool {
        let validScopes:[String] = [BDPScopeUserInfo, BDPScopeUserLocation, BDPScopeRecord, BDPScopeWritePhotosAlbum, BDPScopeClipboard, BDPScopeRunData]

        if validScopes.contains(scope) {
            return true
        }

        if scope == BDPScopeAppBadge && EMAFeatureGating.boolValue(forKey: EEFeatureGatingKeyGadgetOpenAppBadge) {
            return true
        }

        return false
    }

    // MARK: Life Cycle
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "authorize", pluginType: Self.self, paramsType: OpenAPIAuthorizationParams.self, resultType: OpenAPIAuthorizationResult.self) { (this, params, context, gadgetContext, callback) in
            
            let enable = OpenAPIFeatureKey.authorize.isEnable()
            if enable {
                this.authorizeV2(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            } else {
                this.authorize(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            }
        }
    }
}

extension OPAppType {
    var applicationTypeString: String {
        var typeString = ""
        switch self {
        case .gadget:
            typeString = "MP"
        case .webApp:
            typeString = "H5"
        default:
            typeString = ""
        }
        return typeString
    }
}

extension BDPAuthorizationPermissionResult {
    var authorizeStateString: String {
        var permissionString = ""
        switch self {
        case .enabled:
            permissionString = "approved"
        default:
            permissionString = "rejected"
        }
        return permissionString
    }

    var matchRequestResultString: String {
        var resultStr = "deny"
        switch self {
        case .enabled:
            resultStr = "ok"
        case .userDisabled:
            resultStr = "auth deny"
        case .systemDisabled:
            resultStr = "system auth deny"
        case .invalidScope:
            resultStr = "invalid scope"
        case .platformDisabled:
            resultStr = "platform auth deny"
        default:
            resultStr = "deny"
        }
        return resultStr
    }
}
