//
//  NativeAppApiGateway.swift
//  LarkOpenPlatform
//
//  Created by bytedance on 2022/5/23.
//

import Foundation
import Swinject
import LarkOpenPluginManager
import LarkOpenAPIModel
import TTMicroApp
import ECOProbe
import OPSDK
import EENavigator
import UIKit
import NativeAppPublicKit
import OPPluginManagerAdapter

class NativeAppApiGateway {
    private let pluginManager: OpenPluginManager
    private var nativeAppEngineDic: [String: NativeAppEngine] = [:]
    
    init() {
        self.pluginManager = OpenPluginManager(bizDomain: .openPlatform,
                                               bizType: .thirdNativeApp,
                                               bizScene: "",
                                               asyncAuthorizationChecker: nil)
        registerExtension()
    }
    
    private func registerExtension() {
        // getSystemInfo
        pluginManager.register(OpenAPIGetSystemInfoExtension.self) { resolver, context in
            try OpenAPIGetSystemInfoExtensionNativeAppImpl(extensionResolver: resolver, context: context)
        }
        
        // common
        self.pluginManager.register(OpenAPICommonExtension.self) { _, context in
            OpenAPICommonExtensionAppImpl(gadgetContext: try getGadgetContext(context))
        }
    }
    
    func invokeOpenApi(apiName: String, params: [String: Any], context: OpenAPIContext, callback:@escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        let isSync = isSyncAPI(apiName: apiName)
        if (isSync) {
            let response = pluginManager.syncCall(apiName: apiName, params: params, canUseInternalAPI: false, context: context)
            callback(response)
        } else {
            self.pluginManager.asyncCall(apiName: apiName, params: params, canUseInternalAPI: false, context: context, callback: callback)
        }
    }
    
    public func isSyncAPI(apiName: String) -> Bool {
        if let isSync = pluginManager.defaultPluginConfig[apiName]?.isSync {
            return isSync
        }
        return false
    }
    
    func invokeOpenApi(appID:String, apiName: String, params: [String: Any], callback:@escaping (NativeAppOpenApiModel) -> Void) {
        guard appID != "" else {
            let nativeAppApiModel = NativeAppOpenApiModel(resultType:.fail, data: ["error": "appID should not be empty"])
            callback(nativeAppApiModel)
            return
        }
        var nativeAppEngine: NativeAppEngine?
        if let cacheNativeAppEngine = self.nativeAppEngineDic[appID] {
            nativeAppEngine = cacheNativeAppEngine
        } else {
            let uniqueID = OPAppUniqueID.init(appID: appID, identifier: "", versionType: .current, appType: .thirdNativeApp)
            nativeAppEngine = NativeAppEngine(uniqueID: uniqueID)
            self.nativeAppEngineDic[appID] = nativeAppEngine
            
        }
        let uniqueID = OPAppUniqueID.init(appID: appID, identifier: "", versionType: .current, appType: .thirdNativeApp)
        let appContext = BDPAppContext()
        appContext.engine = nativeAppEngine
        appContext.controller = UIApplication.shared.keyWindow?.rootViewController
        let appTrace = BDPTracingManager.sharedInstance().getTracingBy(nativeAppEngine!.uniqueID)
        let apiTrace = OPTraceService.default().generateTrace(withParent: appTrace, bizName: apiName)
        var additionalInfo: [AnyHashable: Any] = ["gadgetContext": GadgetAPIContext(with: appContext)]
        
        let context = OpenAPIContext(trace: OPTrace(traceId: apiName),
                                     dispatcher: pluginManager,
                                     additionalInfo: additionalInfo)
        var nativeAppApiModel: NativeAppOpenApiModel = NativeAppOpenApiModel(resultType: .continue, data: nil)
        self.invokeOpenApi(apiName: apiName, params: params, context: context){ (response) in
            switch response {
            case let .failure(error: error):
                var data = error.additionalInfo
                if data["errCode"] == nil {
                    data["errCode"] = error.outerCode ?? error.code.rawValue
                }
                let statusMsg = error.outerMessage ?? error.code.errMsg
                if !statusMsg.isEmpty {
                    data["errMsg"] = "\(statusMsg) \(data["errMsg"] ?? "")"
                }
                if let errNo = error.errnoError {
                    data["errno"] = "\(errNo.errnoValue)"
                    data["errString"] = "\(errNo.errString)"
                }
                nativeAppApiModel = NativeAppOpenApiModel(resultType:.fail, data: data)
            case let .success(data: data):
                let res = data?.toJSONDict()
                nativeAppApiModel = NativeAppOpenApiModel(resultType:.success, data: res)
            case .continue(event: _, data: _):
                nativeAppApiModel = NativeAppOpenApiModel(resultType:.continue, data: nil)
            }
            callback(nativeAppApiModel)
        }
    }
}
