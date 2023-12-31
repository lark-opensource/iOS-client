//
//  SyncAppReviewRequestConfig.swift
//  TTMicroApp
//
//  Created by xiangyuanyuan on 2021/12/20.
//

import Foundation
import ECOInfra

struct SyncAppReviewRequestConfig: ECONetworkRequestConfig {
    typealias ParamsType = [String: String]?

    typealias ResultType = [String: Any]

    typealias RequestSerializer = ECORequestQueryItemSerializer

    typealias ResponseSerializer = ECOResponseJSONObjSerializer<[String: Any]>

    static var path: String { "/lark/app_interface/app/review/" }
    
    static var method: ECONetworkHTTPMethod { .GET }
    
    static var requestSerializer: ECORequestQueryItemSerializer { ECORequestQueryItemSerializer() }
    
    static var responseSerializer: ECOResponseJSONObjSerializer<[String: Any]> { ECOResponseJSONObjSerializer<[String: Any]>() }
    
    static var initialHeaders: [String : String] { ["Content-Type": "application/json"] }
    
    static var middlewares: [ECONetworkMiddleware] {
        [
            AppReviewDomainMiddleware(),
            AppReviewHeaderInjector(),
            AppReviewSyncPathMiddleware(),
            OPRequestTraceMiddleware(),
            OPRequestLogMiddleware()
        ] as [ECONetworkMiddleware]
    }
}
