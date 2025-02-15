//
//  OpenPluginRequestAccessAPI.swift
//  LarkOpenApis
//
//  GENERATED BY ANYCODE on 2023/6/14 03:34:11
//

import Foundation
import LarkOpenAPIModel
import OPPluginManagerAdapter
import LarkOpenPluginManager
import LarkContainer
import LarkAccountInterface
import WebBrowser
import TTMicroApp

// MARK: - OpenPluginRequestAccessAPI
final class OpenPluginRequestAccessAPI: OpenBasePlugin {
    
    @ScopedProvider private var userService: PassportUserService?
    @Provider private var webSessionUpdate: OpenAPIWebSessionUpdate // Global
    
    func requestAccess(
        params: OpenPluginRequestAccessRequest,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenPluginRequestAccessResponse>) -> Void) {
            let uniqueID = gadgetContext.uniqueID
            let appType = uniqueID.appType
            var appID = uniqueID.appID
            if appType == .webApp { // 网页应用必传
                guard let webAppAppID = params.appID else {
                    callback(.failure(error: OpenAPIError(errno: OpenAPICommonErrno.invalidParam(.paramCannotEmpty(param: "appID")))))
                    return
                }
                
                guard !webAppAppID.isEmpty else {
                    callback(.failure(error: OpenAPIError(errno: OpenAPICommonErrno.invalidParam(.invalidParam(param: "appID")))))
                    return
                }
                
                appID = webAppAppID
            }
            let scope = params.scopeList.joined(separator: " ")
            let openAppType = Self.openAppTypeValueFromOPAppType(appType)
            var redirectURL: String? = nil
            if let browser = gadgetContext.controller as? WebBrowser {
                redirectURL = browser.webview.url?.absoluteString
            }
            let authParams = OpenAPIAuthParams(appID: appID, scope: scope, state: params.state, redirectUri: redirectURL, openAppType: openAppType)
            
            guard let userService else {
                callback(.failure(error: OpenAPIError(errno: OpenAPICommonErrno.internalError).setMonitorMessage("resolve PassportUserService failed")))
                return
            }
            
            var onceFlag = false
            userService.requestOpenAPIAuth(params: authParams) { [weak self] result in
                if onceFlag { return } // 回调保护
                onceFlag = true
                
                switch result {
                case .success(let payload):
                    var firstPartyLoginOptEnabled: Bool? = nil
                    if FirstPartyMicroAppLoginOpt.shared.cookieValidForUniqueID(uniqueID) {
                        firstPartyLoginOptEnabled = true
                    }
                    
                    do {
                        guard let session = payload.extra?["open_session"] as? String, !session.isEmpty else {
                            throw OpenAPIError(errno: OpenAPIRequestAccessErrno.emptySession)
                        }
                        
                        // 更新session缓存
                        if appType == .webApp {
                            guard let browser = gadgetContext.controller as? WebBrowser, let url = browser.webview.url else {
                                throw OpenAPIError(errno: OpenAPICommonErrno.internalError).setMonitorMessage("get browser info failed")
                            }
                            
                            self?.webSessionUpdate.updateSession(session, url: url, browser: browser)
                        } else {
                            try OpenPluginUser.updateSession(session, for: uniqueID)
                        }
                        
                        callback(.success(data: OpenPluginRequestAccessResponse(code: payload.code, firstPartyLoginOptEnabled: firstPartyLoginOptEnabled, state: params.state)))
                    } catch let apiError as OpenAPIError {
                        callback(.failure(error: apiError))
                    } catch {
                        callback(.failure(error: OpenAPIError(errno: OpenAPICommonErrno.unknown).setMonitorMessage(error.localizedDescription)))
                    }
                case .failure(let authError):
                    switch authError {
                    case .error(let errorInfo):
                        let error = OpenAPIRequestAccessErrno.authFailed(code: String(errorInfo.code), message: errorInfo.message)
                        callback(.failure(error: OpenAPIError(errno: error)))
                    @unknown default:
                        callback(.failure(error: OpenAPIError(errno: OpenAPICommonErrno.unknown)))
                    }
                }
            }
        }
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "requestAccess", pluginType: Self.self, paramsType: OpenPluginRequestAccessRequest.self, resultType: OpenPluginRequestAccessResponse.self) { (this, params, context, gadgetContext, callback) in
            context.apiTrace.info("requestAccess API call start")
            this.requestAccess(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            context.apiTrace.info("requestAccess API call end")
        }
    }
}

extension OpenPluginRequestAccessAPI {
    
    static func openAppTypeValueFromOPAppType(_ appType: OPAppType) -> Int? {
        switch appType {
        case .gadget: return 1
        case .webApp: return 2
        case .block: return 3
        default: break
        }
        
        return nil
    }
}
