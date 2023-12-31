//
//  OpenPluginNativeAppContainer.swift
//  LarkOpenPlatform
//
//  Created by bytedance on 2022/6/22.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import NativeAppPublicKit
import LarkContainer

open class OpenPluginNativeAppContainer: OpenBasePlugin {
    private let nativeAppPluginManager: NativeAppPluginManager

    required public init(resolver: UserResolver) {
        self.nativeAppPluginManager = NativeAppPluginManager()
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "invokeCustomAPI", pluginType: Self.self) { (this, params, context, callback) in
            if let params = params as? OpenAPINativeAppParams, let apiName = params.params["name"] as? String {
                guard this.nativeAppPluginManager.pluginConfigs[apiName] != nil else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setOuterMessage("can not find apiName in plist")
                    callback(.failure(error: error))
                    context.apiTrace.error("invokeCustomAPI Plugin: can not find apiName in plist, apiName:\(apiName).")
                    return
                }
                context.apiTrace.info("invokeCustomAPI Plugin: invoke custom api, apiName:\(apiName)")
                let realParams: [AnyHashable: Any] = params.params
                this.invokeNativeAppAPI(apiName: apiName, params: realParams, context:context) { (response) in
                    switch response.resultType {
                    case .success:
                        context.apiTrace.info("invokeCustomAPI Plugin: invoke custom api success,apiName:\(apiName)")
                        let dataDic = response.toJSONDict() ?? [:]
                        let result = OpenAPINativeAppResult(data: dataDic)
                        callback(.success(data: result))
                    case .fail:
                        context.apiTrace.error("invokeCustomAPI Plugin: invoke custom api fail,apiName:\(apiName)")
                        let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        if let errMsg = Self.toJSONString(dict: response.data) {
                            error.setOuterMessage(errMsg)
                        }
                        callback(.failure(error: error))
                    case .continue:
                        assertionFailure("should not enter here")
                    }
                }
            } else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setOuterMessage("no apiName params")
                callback(.failure(error: error))
            }
        }
    }
    
    private func invokeNativeAppAPI(apiName: String, params: [AnyHashable: Any], context: OpenAPIContext, callback: @escaping (NativeAppAPIBaseResult) -> Void) {
        let isSync: Bool = nativeAppPluginManager.pluginConfigs[apiName]!.isSync
        if isSync {
            let response = nativeAppPluginManager.syncCall(apiName: apiName, params: params, context: context)
            callback(response)
        } else {
            nativeAppPluginManager.asyncCall(apiName: apiName, params: params, context: context, callback: callback)
        }
    }
    
    private static func toJSONString(dict: [AnyHashable: Any]?) -> String? {
        guard let dict = dict else {
            return nil
        }
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.init(rawValue: 0)) else { return nil }
        let strJson = NSString(data: data, encoding: NSUTF8StringEncoding)
        return strJson as String?
    }
}
