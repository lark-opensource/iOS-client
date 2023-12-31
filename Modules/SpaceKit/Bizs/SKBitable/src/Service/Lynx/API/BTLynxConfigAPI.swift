//
//  BTLynxGetFgConfigAPI.swift
//  SKBitable
//
//  Created by Nicholas Tau on 2023/11/8.
//

import Foundation
import SKFoundation
import LarkLynxKit
import BDXLynxKit
import LarkContainer
import LarkSetting
import LarkFeatureGating

public final class BTLynxGetFgConfigAPI: NSObject, BTLynxAPI {
    @Injected private var containerEnvService: BTLynxContainerEnvService
    static let apiName = "getFgConfig"
    /**
     调用OpenAPI

     - Parameters:
       - apiName: API名
       - params: 调用API时的入参
       - callback: Lynx JSBridge回调
     */
    func invoke(params: [AnyHashable : Any],
                lynxContext: LynxContext?,
                bizContext: LynxContainerContext?,
                callback:  BTLynxAPICallback<BTLynxAPIBaseResult>?) {
        guard let keys = params["keys"] as? [String] else {
            callback?(.failure(error: BTLynxAPIError(code: .paramsError).insertUserInfo(key: "key", value: "keys")))
            return
        }
        guard let userResolver = containerEnvService.resolver as? UserResolver else {
            callback?(.failure(error: BTLynxAPIError(code: .internalError).insertUserInfo(key: "info", value: "resolver unwrapper error")))
            return
        }
        if keys.isEmpty {
            callback?(.success(data: BTLynxAPIBaseResult(dataString: "")))
        } else {
            let result = keys.compactMap { key in
                let value = userResolver.fg.dynamicFeatureGatingValue(with: FeatureGatingManager.Key(stringLiteral: key))
                return [key: value]
            }
            let JSONString = result.toJSONString() ?? ""
            callback?(.success(data: BTLynxAPIBaseResult(dataString: JSONString)))
        }
    }
}

public final class BTLynxGetSettingsConfigAPI: NSObject, BTLynxAPI {
    @Injected private var containerEnvService: BTLynxContainerEnvService
    static let apiName = "getSettingsConfig"
    /**
     调用OpenAPI

     - Parameters:
       - apiName: API名
       - params: 调用API时的入参
       - callback: Lynx JSBridge回调
     */
    func invoke(params: [AnyHashable : Any],
                lynxContext: LynxContext?,
                bizContext: LynxContainerContext?,
                callback:  BTLynxAPICallback<BTLynxAPIBaseResult>?) {
        guard let keys = params["keys"] as? [String] else {
            callback?(.failure(error: BTLynxAPIError(code: .paramsError).insertUserInfo(key: "key", value: "keys")))
            return
        }
        guard let userResolver = containerEnvService.resolver as? UserResolver else {
            callback?(.failure(error: BTLynxAPIError(code: .internalError).insertUserInfo(key: "info", value: "resolver unwrapper error")))
            return
        }
        if keys.isEmpty {
            callback?(.success(data: BTLynxAPIBaseResult(dataString: "")))
        } else {
            let result = keys.compactMap { key in
                do {
                    let value = try userResolver.settings.setting(with: key)
                    return [key: value]
                } catch {
                    DocsLogger.btWarn("fetch setting: \(key) with error: \(error)")
                }
                //默认返回 key：空字符串 的匹配
                return [key: [:]]
            }
            let JSONString = result.toJSONString() ?? ""
            callback?(.success(data: BTLynxAPIBaseResult(dataString: JSONString)))
        }
    }
}
