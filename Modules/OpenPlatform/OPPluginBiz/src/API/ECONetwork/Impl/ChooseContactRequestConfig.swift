//
//  ChooseContactRequestConfig.swift
//  EEMicroAppSDK
//
//  Created by xiangyuanyuan on 2021/11/15.
//

import Foundation
import ECOInfra

struct ChooseContactRequestConfig: ECONetworkRequestConfig {
    
    typealias ParamsType = [String: Any]

    typealias ResultType = [String: Any]

    typealias RequestSerializer = ECORequestBodyJSONSerializer

    typealias ResponseSerializer = ECOResponseJSONObjSerializer<[String: Any]>
    
    static var path: String {"/open-apis/mina/getOpenDepIDsByDepIDs"}
    
    static var method: ECONetworkHTTPMethod { .POST }
    
    static var requestSerializer: ECORequestBodyJSONSerializer { ECORequestBodyJSONSerializer() }
    
    static var responseSerializer: ECOResponseJSONObjSerializer<[String: Any]> { ECOResponseJSONObjSerializer<[String: Any]>() }
    
    static var initialHeaders: [String : String] { ["Content-Type": "application/json"]}

    static var middlewares: [ECONetworkMiddleware] {
        [
            EMADomainMiddleware(),
            EMANetworkCipherMiddleware(resultKey: "openDepIDs"),
            OPRequestTraceMiddleware(),
            OPRequestLogMiddleware()
        ] as [ECONetworkMiddleware]
    }
}
