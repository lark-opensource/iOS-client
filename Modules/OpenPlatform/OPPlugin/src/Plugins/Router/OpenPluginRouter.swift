//
//  OpenPluginRouter.swift
//  OPPlugin
//
//  Created by yi on 2021/2/20.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import ECOProbe
import LarkFeatureGating
import ECOInfra
import WebBrowser
import EENavigator
import LarkContainer
import TTMicroApp

final class OpenPluginRouter: OpenBasePlugin {

    // 该接口已经废弃，请使用 tt.openSchema 接口（在小程序开发者完成接口迁移后可移除）
    func openOuterURL(params: OpenAPIOpenOuterURLParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {

        guard let gadgetContext = context.gadgetContext, let controller = gadgetContext.controller else {
            context.apiTrace.error("gadgetContext nil? \(context.gadgetContext == nil)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("gadgetContext nil? \(context.gadgetContext == nil)")
            callback(.failure(error: error))
            return
        }
        let uniqueID = gadgetContext.uniqueID
        let openURLStr = params.url
        DispatchQueue.main.async {
            guard let routerPlugin = BDPTimorClient.shared().routerPlugin.sharedPlugin() as? BDPRouterPluginDelegate else {
                context.apiTrace.error("has no BDPRouterPluginDelegate for \(uniqueID)")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("has no BDPRouterPluginDelegate for \(uniqueID)")
                callback(.failure(error: error))
                return
            }

            guard let url = URL(string: openURLStr) else {
                context.apiTrace.error("url invalid length=\(openURLStr.count)")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("url invalid length=\(openURLStr.count)")
                callback(.failure(error: error))
                return
            }
            let result = routerPlugin.bdp_openSchema?(with: url, uniqueID: uniqueID, appType: uniqueID.appType, external: true, from: controller, whiteListChecker: nil)
            if result == .success {
                callback(.success(data: nil))
            } else {
                let error = OpenAPIError(code: OpenOuterURLErrorCode.failed)
                    .setOuterMessage("host app open schema failed")
                callback(.failure(error: error))
            }
        }
    }
    
    private func processOpenSchemaResult(_ result: BDPOpenSchemaResult, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void, refactorEnabled: Bool) {
        if result == .success {
            callback(.success(data: nil))
        } else {
            let error = OpenAPIError(code: OpenschemaErrorCode.openFailed)
                .setOuterMessage("host app open schema failed")
                .setErrno(OpenAPICommonErrno.internalError)
            if refactorEnabled {
                error.setErrno(result == .authFailed ? OpenAPIOpenSchemaErrno.notAllowed : OpenAPIOpenSchemaErrno.redirectFailed)
            }
            
            callback(.failure(error:error))
        }
    }

    func openSchema(params: OpenAPIOpenSchemaParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        
        let refactorEnabled = OpenSchemaRefactorPolicy.refactorEnabled
        
        let originSchema = params.schema
        if refactorEnabled, originSchema.isEmpty {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setOuterMessage("parameter value invalid: schema")
                .setErrno(OpenAPIOpenSchemaErrno.emptySchema)
            callback(.failure(error: error))
            return
        }
        
        guard let routerPlugin = BDPTimorClient.shared().routerPlugin.sharedPlugin() as? BDPRouterPluginDelegate, let router = routerPlugin.bdp_openSchema else {
            context.apiTrace.error("has no BDPRouterPluginDelegate")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                .setErrno(OpenAPICommonErrno.unable)
                .setOuterMessage("host app not supported")
                .setMonitorMessage("has no BDPRouterPluginDelegate")
            callback(.failure(error: error))
            return
        }
        
        let schema = originSchema.trimmingCharacters(in: .whitespaces)
        
        var url: URL?
        if URLEncodeNormalization(resolver: userResolver).enabled(in: .api_openSchema) {
            do {
                url = try URL.forceCreateURL(string: schema)
            } catch {
                context.apiTrace.error("force create URL failed: \(error)")
            }
        } else {
            let mutableSet = NSMutableCharacterSet.alphanumeric()
            mutableSet.formIntersection(with: CharacterSet(charactersIn: "#:/;?+-.@&=%$_!*'(),{}|^~[]`<>\\\""))
            if let urlString = schema.addingPercentEncoding(withAllowedCharacters: mutableSet.inverted) {
                url = URL(string: urlString)
            } else {
                context.apiTrace.error("URL addingPercentEncoding failed")
            }
        }
        
        guard let validURL = url else {
            let error = OpenAPIError(code: OpenschemaErrorCode.illegalSchema)
                .setErrno(OpenAPIOpenSchemaErrno.invalidSchema)
                .setOuterMessage("illegal schema param")
                .setMonitorMessage("invalid schema: \(originSchema)")
            callback(.failure(error: error))
            return
        }
        
        let uniqueID = gadgetContext.uniqueID

        if !refactorEnabled {
            var failErrMsg: NSString?
            var canOpenSchema = false
            if uniqueID.appType == .webApp || uniqueID.appType == .widget {
                canOpenSchema = true
            } else {
                var dest: NSURL? = validURL as NSURL
                if let auth = gadgetContext.authorization {
                    canOpenSchema = auth.checkSchema(&dest, uniqueID: uniqueID, errorMsg: &failErrMsg)
                }
            }
            if !canOpenSchema {
                let error = OpenAPIError(code: OpenschemaErrorCode.openFailed)
                    .setOuterMessage((failErrMsg ?? "") as String)
                    .setErrno(OpenAPIOpenSchemaErrno.notAllowed)
                callback(.failure(error: error))
                return
            }
        }
        
        let external = params.external
        
        var closeWebSelf = false
        if let webBrowser = context.controller as? WebBrowser {
            closeWebSelf = webBrowser.canCloseSelf(with: validURL, scene: .open_schema)
        }
        
        if closeWebSelf {
            let browser = context.controller as? WebBrowser
            browser?.closeSelfMonitor(with: url, scene: .open_schema)
            let result = router(validURL, uniqueID, uniqueID.appType, external, gadgetContext.controller, gadgetContext.authorization)
            processOpenSchemaResult(result, callback: callback, refactorEnabled: refactorEnabled)
            browser?.delayRemoveSelfInViewControllers()
        } else {
            //(默认, 不关闭自身)原线上逻辑
            let result = router(validURL, uniqueID, uniqueID.appType, external, gadgetContext.controller, gadgetContext.authorization)
            processOpenSchemaResult(result, callback: callback, refactorEnabled: refactorEnabled)
        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "openOuterURL", pluginType: Self.self, paramsType: OpenAPIOpenOuterURLParams.self) { (this, params, context, gadgetContext, callback) in
            
            this.openOuterURL(params: params, context: context, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: "openSchema", pluginType: Self.self, paramsType: OpenAPIOpenSchemaParams.self) { (this, params, context, gadgetContext, callback) in
            
            this.openSchema(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}
