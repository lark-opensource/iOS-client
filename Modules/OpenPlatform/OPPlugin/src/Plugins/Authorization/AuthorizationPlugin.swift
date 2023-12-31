//
//  AuthorizationPlugin.swift
//  OPPlugin
//
//  Created by 王飞 on 2022/3/25.
//

import OPFoundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import OPSDK
import TTMicroApp

private func genError(_ code: OpenAPICommonErrorCode) -> OpenAPIError {
    OpenAPIError(code: code)
}

extension OpenPluginAuthorization {
    
    enum AuthAPIMonitorName: String {
        case invoke = "api_invoke_authorize"
        case callback = "api_authorize_callback"
    }
    
    private func authTracing(name: AuthAPIMonitorName, scope: String, uniqueID: OPAppUniqueID) {
        let params = [
            "authorize_scope": scope,
            "app_id": uniqueID.appID,
            "application_type": uniqueID.appType.applicationTypeString,
            "appname": BDPCommonManager.shared()?.getCommonWith(uniqueID)?.model.name ?? ""
        ]
        BDPTracker.event(name.rawValue, attributes: params, uniqueID: uniqueID)
    }
    
    func authorization(forAPIContext context: GadgetAPIContext) throws -> BDPAuthorization {
        guard let auth = context.authorization else {
            throw genError(.unknown)
        }
        return auth
    }
    
    func viewController(forAPIContext context: GadgetAPIContext) throws -> UIViewController {
        guard let controller = context.controller else {
            throw genError(.internalError)
        }
        return controller
    }
    
    func transfromScope(forScope scope: String) throws -> String {
        guard let innerScope = BDPAuthorization.transfromScope(toInnerScope: scope) else {
            throw genError(.internalError)
        }
        return innerScope
    }
    
    func checkAuth(result: BDPAuthorizationPermissionResult) throws {
        switch result {
        case .enabled:
            // do nothing
            break
        case .systemDisabled:
            throw genError(.systemAuthDeny)
        case .userDisabled:
            throw genError(.userAuthDeny)
        default:
            throw genError(.unknown)
        }
    }
    
    func authorizeV2(params: OpenAPIAuthorizationParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping(OpenAPIBaseResponse<OpenAPIAuthorizationResult>) -> Void) {
        do {
            context.apiTrace.info("authorizeV2 api begin")
            let scope = params.scope
            let uniqueID = gadgetContext.uniqueID
            authTracing(name: .invoke, scope: scope, uniqueID: uniqueID)
            let auth = try authorization(forAPIContext: gadgetContext)
            context.apiTrace.info("authorizeV2 auth generate done")
            let vc = try viewController(forAPIContext: gadgetContext)
            context.apiTrace.info("authorizeV2 viewController generate done")
            let innerScope = try transfromScope(forScope: scope)
            context.apiTrace.info("authorizeV2 innerScope generate done")

            let provider = BDPAuthModuleControllerProvider()
            provider.controller = vc
            auth.requestUserPermission(forScopeIfNeeded: innerScope,
                                       uniqueID: uniqueID,
                                       authProvider: auth,
                                       delegate: provider) { [weak self] (result) in
                do {
                    context.apiTrace.info("authorizeV2 requestUserPermission done")
                    guard let self = self else {
                        context.apiTrace.error("authorizeV2 self is nil")
                        throw genError(.internalError)
                    }
                    try self.checkAuth(result: result)
                    context.apiTrace.info("authorizeV2 checkAuth done")
                    callback(.success(data: OpenAPIAuthorizationResult()))
                    context.apiTrace.info("authorizeV2 api done")
                } catch let e as OpenAPIError {
                    context.apiTrace.error(e.outerMessage ?? OpenAPICommonErrorCode.unknown.errMsg)
                    callback(.failure(error: e))
                } catch {
                    // 正常不应该调用到这里的
                    assertionFailure()
                    context.apiTrace.error(OpenAPICommonErrorCode.unknown.errMsg)
                    callback(.failure(error: genError(.unknown)))
                }
            }
        } catch let e as OpenAPIError {
            context.apiTrace.error(e.outerMessage ?? OpenAPICommonErrorCode.unknown.errMsg)
            callback(.failure(error: e))
        } catch {
            // 正常不应该调用到这里的
            assertionFailure()
            context.apiTrace.error(OpenAPICommonErrorCode.unknown.errMsg)
            callback(.failure(error: genError(.unknown)))
        }
    }
}
