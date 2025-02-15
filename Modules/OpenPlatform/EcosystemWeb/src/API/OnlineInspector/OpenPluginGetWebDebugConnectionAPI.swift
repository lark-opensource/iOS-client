//
//  OpenPluginGetWebDebugConnectionAPI.swift
//  LarkOpenApis
//
//  GENERATED BY ANYCODE on 2023/9/6 03:51:57
//

import Foundation
import LarkOpenAPIModel
import TTMicroApp
import LarkOpenPluginManager
import LarkAccountInterface
import UniverseDesignToast
import LarkContainer
import WebBrowser

// MARK: - OpenPluginGetWebDebugConnectionRequest
final class OpenPluginGetWebDebugConnectionRequest: OpenAPIBaseParams {
    
    /// description: 应用ID
    @OpenAPIRequiredParam(
            userRequiredWithJsonKey: "appId")
    var appId: String
    
    /// description: 调试页面地址
    @OpenAPIRequiredParam(
            userRequiredWithJsonKey: "debugPageUrl")
    var debugPageUrl: String
    
    /// description: 调试者debugSession
    @OpenAPIRequiredParam(
            userRequiredWithJsonKey: "debugSession")
    var debugSession: String
    
    /// description: debugSession检测级别
    @OpenAPIRequiredParam(
            userRequiredWithJsonKey: "debugSessionCheckLevel")
    var debugSessionCheckLevel: Int
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_appId, _debugPageUrl, _debugSession, _debugSessionCheckLevel]
    }
}

// MARK: - OpenPluginGetWebDebugConnectionAPI
final class OpenPluginGetWebDebugConnectionAPI: OpenBasePlugin {
        
    func getWebDebugConnection(
        params: OpenPluginGetWebDebugConnectionRequest,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenPluginGetWebDebugConnectionResponse>) -> Void) {
            
        guard let apiContext = context.additionalInfo["gadgetContext"] as? OPAPIContextProtocol,
            let browser = apiContext.controller as? WebBrowser else {
            let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                .setMonitorMessage("can not get WebBrowser")
            context.apiTrace.error("can not get WebBrowser")
            callback(.failure(error: error))
            return
        }
        
        guard let service = try? resolver.resolve(assert: DeviceService.self) else {
            let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                .setMonitorMessage("deviceService is nil")
            context.apiTrace.error("deviceService is nil")
            callback(.failure(error: error))
            return
        }
            
        guard let onlineInspectorExtension = browser.resolve(WebOnlineInspectorExtensionItem.self) else {
            let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                .setMonitorMessage("onlineInspectorExtension is nil")
            context.apiTrace.error("onlineInspectorExtension is nil")
            callback(.failure(error: error))
            return
        }
            
        let browserHost = browser.browserURL?.host ?? ""
        let debugPageUrlWithoutQuery = params.debugPageUrl.urlWithoutQuery() ?? ""  //去除query
        let debugHost = URL(string: debugPageUrlWithoutQuery)?.host ?? ""
        if !WebOnlineInspectorValidator.allowDebugHost(for: browserHost) || !WebOnlineInspectorValidator.allowDebugHost(for: debugHost) {
            let error = OpenAPIError(errno: OpenAPICommonErrno.unknown)
                .setMonitorMessage("not allow debug this host")
            context.apiTrace.error("not allow debug this host")
            callback(.failure(error: error))
            UDToast.showFailure(with: BundleI18n.EcosystemWeb.WebAppTool_WebAppRemoteDebug_UnableToDebugCurrentPage, on: browser.view)
            return
        }
        
        if params.appId.isEmpty || debugPageUrlWithoutQuery.isEmpty || params.debugSession.isEmpty  {
            let error = OpenAPIError(errno: OpenAPICommonErrno.invalidParam(.paramWrongType(param: "some params missing")))
                .setMonitorMessage("some params missing")
            context.apiTrace.error("some params missing")
            callback(.failure(error: error))
            return
        }
           
        let networkContext = OpenECONetworkWebContext(trace: browser.getTrace(), source: .web)
        WebOnlineInspectNetwork.getWebDebugConnection(appId: params.appId, debugPageUrl: debugPageUrlWithoutQuery, debugSession: params.debugSession, deviceID: service.deviceId, debugSessionCheckLevel: params.debugSessionCheckLevel, context: networkContext){ [weak browser] result in
            switch result {
            case .success(let connRes):
                if let connRes = connRes {
                    onlineInspectorExtension.onlineConnIDs.insert(connRes.connId)
                    context.apiTrace.info("getWebDebugConnection response success: \(connRes.connId)")
                    callback(.success(data: connRes))
                } else {
                    let error = OpenAPIError(errno: OpenAPICommonErrno.unknown)
                        .setMonitorMessage("getWebDebugConnection response no data")
                    context.apiTrace.error("getWebDebugConnection response no data")
                    callback(.failure(error: error))
                    if let supperView = browser?.view {
                        UDToast.showFailure(with: BundleI18n.EcosystemWeb.WebAppTool_WebAppRemoteDebug_UnableToCreateChannelDebugging, on: supperView)
                    }
                }
            case .failure(let err):
                let errorMsg = "getWebDebugConnection response failure: \(err.localizedDescription)"
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    .setMonitorMessage(errorMsg)
                context.apiTrace.error(errorMsg)
                callback(.failure(error: error))
                if let supperView = browser?.view {
                    var msg = err.localizedDescription
                    if msg.count <= 0 {
                        msg = BundleI18n.EcosystemWeb.WebAppTool_WebAppRemoteDebug_UnableToCreateChannelDebugging
                    }
                    UDToast.showFailure(with: msg, on: supperView)
                }
            }
        }
    }
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "getWebDebugConnection", pluginType: Self.self, paramsType: OpenPluginGetWebDebugConnectionRequest.self, resultType: OpenPluginGetWebDebugConnectionResponse.self) { (this, params, context, gadgetContext, callback) in
            context.apiTrace.info("getWebDebugConnection API call start")
            if OPUserScope.userResolver().fg.staticFeatureGatingValue(with: "openplatform.browser.remote.debug.client_enable") {
                context.apiTrace.info("getWebDebugConnection API impl exec")
                this.getWebDebugConnection(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            }
            context.apiTrace.info("getWebDebugConnection API call end")
        }
    }
}
