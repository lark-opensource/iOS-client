//
//  File.swift
//  EEMicroAppSDK
//
//  Created by xiangyuanyuan on 2021/8/23.
//

import Foundation
import ECOInfra

struct WebVerifyRequestConfig: ECONetworkRequestConfig  {
    typealias ParamsType = [String: Any]

    typealias ResultType = [String: Any]

    typealias RequestSerializer = ECORequestBodyJSONSerializer

    typealias ResponseSerializer = ECOResponseJSONObjSerializer<[String: Any]>
    
    static var path: String {"/open-apis/mina/jssdk/verify"}
    
    static var method: ECONetworkHTTPMethod { .POST }
    
    static var requestSerializer: ECORequestBodyJSONSerializer { ECORequestBodyJSONSerializer() }
    
    static var responseSerializer: ECOResponseJSONObjSerializer<[String: Any]> { ECOResponseJSONObjSerializer<[String: Any]>() }
    
    static var initialHeaders: [String : String] { ["Content-Type": "application/json"]}
    
    static var middlewares: [ECONetworkMiddleware] {
        [
            EMADomainMiddleware(),
            LarkSessionInjector(larkSessionKey: .X_Session_ID),
            OPRequestTraceMiddleware(),
            OPRequestLogMiddleware()
        ] as [ECONetworkMiddleware]
    }
}


struct WebVerifyWithoutSessionRequestConfig: ECONetworkRequestConfig  {
    typealias ParamsType = [String: Any]

    typealias ResultType = [String: Any]

    typealias RequestSerializer = ECORequestBodyJSONSerializer

    typealias ResponseSerializer = ECOResponseJSONObjSerializer<[String: Any]>
    
    static var path: String {"/open-apis/mina/jssdk/verify"}
    
    static var method: ECONetworkHTTPMethod { .POST }
    
    static var requestSerializer: ECORequestBodyJSONSerializer { ECORequestBodyJSONSerializer() }
    
    static var responseSerializer: ECOResponseJSONObjSerializer<[String: Any]> { ECOResponseJSONObjSerializer<[String: Any]>() }
    
    static var initialHeaders: [String : String] { ["Content-Type": "application/json"]}

    static var middlewares: [ECONetworkMiddleware] {
        [
            EMADomainWithoutLoginMiddleware(),
            OPRequestTraceMiddleware(),
            OPRequestLogMiddleware()
        ] as [ECONetworkMiddleware]
    }
}


