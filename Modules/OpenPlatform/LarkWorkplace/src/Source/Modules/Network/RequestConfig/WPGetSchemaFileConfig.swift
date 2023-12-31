//
//  WPGetSchemaFileConfig.swift
//  LarkWorkplace
//
//  Created by Jiayun Huang on 2022/12/3.
//

import Foundation
import ECOInfra
import SwiftyJSON

/// 请求模板化文件
struct WPGetSchemaFileConfig: ECONetworkRequestConfig {
    typealias RequestSerializer = ECORequestQueryItemSerializer

    typealias ResponseSerializer = ECOResponseJSONSerializer

    typealias ParamsType = [String: String]?

    typealias ResultType = JSON

    static var requestSerializer: RequestSerializer {
        ECORequestQueryItemSerializer()
    }

    static var responseSerializer: ResponseSerializer {
        ECOResponseJSONSerializer()
    }

    static var path: String {
        return ""
    }

    static var method: ECONetworkHTTPMethod {
        return .GET
    }

    static var initialHeaders: [String: String] {
        return WPGeneralRequestConfig.initialHeaders
    }

    static var middlewares: [ECONetworkMiddleware] {
        return WPGeneralRequestConfig.middlewares
    }
}
