//
//  FetchChatIDByOpenChatIDsRequestConfig.swift
//  EEMicroAppSDK
//
//  Created by MJXin on 2021/6/16.
//

import Foundation
import ECOInfra

struct FetchChatIDByOpenChatIDsRequestConfig: ECONetworkRequestConfig  {
    
    typealias ParamsType = [String: Any]
    
    typealias ResultType = [String: Any]
    
    typealias RequestSerializer = ECORequestBodyJSONSerializer
    
    typealias ResponseSerializer = ECOResponseJSONObjSerializer<[String: Any]>
    
    static var path: String { "/open-apis/mina/" + "getChatIDsByOpenChatIDs"}
    
    static var method: ECONetworkHTTPMethod { .POST }
    
    static var requestSerializer: ECORequestBodyJSONSerializer { ECORequestBodyJSONSerializer() }
    
    static var responseSerializer: ECOResponseJSONObjSerializer<[String: Any]> { ECOResponseJSONObjSerializer<[String: Any]>() }
    
    static var initialHeaders: [String : String] { ["Content-Type": "application/json"]}
    
    static var middlewares: [ECONetworkMiddleware] {
        [
            EMADomainMiddleware(),
            EMANetworkCipherMiddleware(resultKey: "chatids"),
            EMAAPIRequestCommonParamsMiddleware(),
            EMASessionInjector(),
            EMAResponseVerifyMiddleware(),
            OPRequestCommonParamsMiddleware(),
            OPRequestTraceMiddleware(),
            OPRequestLogMiddleware()
        ] as [ECONetworkMiddleware]
    }
}
