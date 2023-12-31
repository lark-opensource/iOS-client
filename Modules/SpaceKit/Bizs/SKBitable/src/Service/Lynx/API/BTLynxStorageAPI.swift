//
//  StorageAPI.swift
//  SKBitable
//
//  Created by Nicholas Tau on 2023/11/6.
//

import Foundation
import LarkLynxKit
import BDXLynxKit
import SKFoundation
import LarkContainer

//class BTLynxBaseResponse
public final class BTLynxGetStorageAPI: NSObject, BTLynxAPI {
    @Injected private var containerEnvService: BTLynxContainerEnvService
    static let apiName = "getStorage"
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
        guard let userResolver = containerEnvService.resolver as? UserResolver else {
            callback?(.failure(error: BTLynxAPIError(code: .internalError).insertUserInfo(key: "info", value: "resolver unwrapper error")))
            return
        }
        guard let key = params["key"] as? String else {
            callback?(.failure(error: BTLynxAPIError(code: .paramsError).insertUserInfo(key: "key", value: "key not existed")))
            return
        }
        let dataString = CCMKeyValue.userDefault(userResolver.userID).string(forKey: key) ?? "{}"
        callback?(.success(data: BTLynxAPIBaseResult(dataString: dataString)))
    }
    
}
    
fileprivate extension String {
    func KeyForLynxStorageAPI() -> String {
        return "BTLynxStorageAPI_\(self)"
    }
}

public final class BTLynxSetStorageAPI: NSObject, BTLynxAPI {
    @Injected private var containerEnvService: BTLynxContainerEnvService
    static let apiName = "setStorage"
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
        guard let userResolver = containerEnvService.resolver as? UserResolver else {
            callback?(.failure(error: BTLynxAPIError(code: .internalError).insertUserInfo(key: "info", value: "resolver unwrapper error")))
            return
        }
        
        guard let key = params["key"] as? String else {
            callback?(.failure(error: BTLynxAPIError(code: .paramsError).insertUserInfo(key: "key", value: "key not existed")))
            return
        }
        
        guard let dataString = params["data"] as? String else {
            callback?(.failure(error: BTLynxAPIError(code: .paramsError).insertUserInfo(key: "data", value: "data not existed")))
            return
        }
        CCMKeyValue.userDefault(userResolver.userID).set(dataString, forKey: key)
        callback?(.success(data: BTLynxAPIBaseResult()))
    }
}
