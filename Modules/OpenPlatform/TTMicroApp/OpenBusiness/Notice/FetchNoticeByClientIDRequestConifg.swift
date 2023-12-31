//
//  FetchNoticeByClientIDRequestConifg.swift
//  TTMicroApp
//
//  Created by ChenMengqi on 2021/8/9.
//

import Foundation
import ECOInfra

struct FetchNoticeByClientIDRequestConifg: ECONetworkRequestConfig {
    typealias ParamsType = [String: Any]
    
    typealias ResultType = [String: Any]
    
    typealias RequestSerializer = ECORequestBodyJSONSerializer
    
    typealias ResponseSerializer = ECOResponseJSONObjSerializer<[String: Any]>
    
    static var path: String { "/lark/app_interface" + "/api/notification"}
    
    static var method: ECONetworkHTTPMethod { .POST }
    
    static var requestSerializer: ECORequestBodyJSONSerializer { ECORequestBodyJSONSerializer() }
    
    static var responseSerializer: ECOResponseJSONObjSerializer<[String: Any]> { ECOResponseJSONObjSerializer<[String: Any]>() }
    
    static var initialHeaders: [String : String] { ["Content-Type": "application/json"]}
    
    static var middlewares: [ECONetworkMiddleware] {
        [
            TTDomainMiddleware(),
            TTSessionInjector(),
            TTResponseVerifyMiddleware(),
//            OPRequestCommonParamsMiddleware(),
            OPRequestTraceMiddleware(),
            OPRequestLogMiddleware()
        ] as [ECONetworkMiddleware]
    }

}
