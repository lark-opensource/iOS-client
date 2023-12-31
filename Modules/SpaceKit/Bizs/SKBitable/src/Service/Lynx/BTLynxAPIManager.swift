//
//  LynxContainerAPIManager.swift
//  SKBitable
//
//  Created by Nicholas Tau on 2023/11/6.
//

import Foundation
import LarkLynxKit
import BDXLynxKit
import SKFoundation

class BTLynxAPIManager: NSObject, LarkLynxBridgeMethodProtocol {
     
    static let sharedInstance = BTLynxAPIManager()
    
    var apiNameClassMap: [String: BTLynxAPI.Type] = [
        BTLynxLogAPI.apiName: BTLynxLogAPI.self,
        BTLynxGetFgConfigAPI.apiName: BTLynxGetFgConfigAPI.self,
        BTLynxGetSettingsConfigAPI.apiName: BTLynxGetSettingsConfigAPI.self,
        BTLynxGetContainerSizeAPI.apiName: BTLynxGetContainerSizeAPI.self,
        BTLynxOpenFullscreenAPI.apiName: BTLynxOpenFullscreenAPI.self,
        BTLynxReportAPI.apiName: BTLynxReportAPI.self,
        BTLynxSetStorageAPI.apiName: BTLynxSetStorageAPI.self,
        BTLynxGetStorageAPI.apiName: BTLynxGetStorageAPI.self,
        BTLynxHideLoadingAPI.apiName: BTLynxHideLoadingAPI.self,
        BTLynxRequestAPI.apiName: BTLynxRequestAPI.self
    ]
    /**
     调用OpenAPI

     - Parameters:
       - apiName: API名
       - params: 调用API时的入参
       - callback: Lynx JSBridge回调
     */
    func invoke(
        apiName: String!,
        params: [AnyHashable : Any]!,
        lynxContext: LynxContext?,
        bizContext: LynxContainerContext?,
        callback: LynxCallbackBlock?
    ) {
        let wapperCallback: BTLynxAPICallback = {
            switch $0 {
            case .success(let success):
                //构建相应成功的 response
                DocsLogger.btInfo("\(String(describing: apiName)) invoke success")
                if let successResult = success {
                    var resultObject = successResult.toJSONDict()
                    resultObject["apiName"] = apiName
                    callback?(resultObject)
                }
            case .failure(let error):
                //构建相应失败的 response
                DocsLogger.btError("\(String(describing: apiName)) invoke failure with errorInfo:\(error.toJSONDict())")
                var resultObject = error.toJSONDict()
                resultObject["apiName"] = apiName
                callback?(resultObject)
            }
        }
        
        DocsLogger.btInfo("API \(String(describing: apiName)) invoke with params:\(String(describing: params))")
        guard let apiClass = apiNameClassMap[apiName] as? NSObject.Type else {
            wapperCallback(.failure(error: BTLynxAPIError(code: .internalError).insertUserInfo(key: "apiClass", value: "apiClass is nil")))
            DocsLogger.btError("can't find a match class to init with apiName: \(String(describing: apiName))")
            return
        }
        guard let apiObject = apiClass.init() as? BTLynxAPI else {
            wapperCallback(.failure(error: BTLynxAPIError(code: .internalError).insertUserInfo(key: "apiObject", value: "apiObject is nil")))
            DocsLogger.btError("can't find a match class which confirm BitableLynxAPi with apiName: \(String(describing: apiName))")
            return
        }
        DocsLogger.btInfo("\(String(describing: apiName)) will invoke on new object")
        apiObject.invoke(params: params,
                         lynxContext: lynxContext,
                         bizContext: bizContext,
                         callback: wapperCallback)
    }
}

