//
//  WPNormalHomeDataConfig.swift
//  LarkWorkplace
//
//  Created by Jiayun Huang on 2022/11/25.
//

import Foundation
import ECOInfra
import SwiftyJSON
import LarkSetting

/// 老版工作台首页列表数据请求
struct WPNormalHomeDataConfig: ECONetworkRequestConfig {

    typealias RequestSerializer = ECORequestBodyJSONSerializer

    typealias ResponseSerializer = ECOResponseJSONSerializer

    typealias ParamsType = [String: Any]

    typealias ResultType = JSON

    static var requestSerializer: RequestSerializer {
        ECORequestBodyJSONSerializer()
    }

    static var responseSerializer: ResponseSerializer {
        ECOResponseJSONSerializer()
    }

    static var domain: String? {
        return DomainSettingManager.shared.currentSetting[.openAppcenter3]?.first
    }

    static var path: String {
        return "/lark/workplace/api/GetWorkplaceHome"
    }

    static var method: ECONetworkHTTPMethod {
        return .POST
    }

    static var initialHeaders: [String: String] {
        return WPGeneralRequestConfig.initialHeaders
    }

    static var middlewares: [ECONetworkMiddleware] {
        return WPGeneralRequestConfig.middlewares
    }
}
