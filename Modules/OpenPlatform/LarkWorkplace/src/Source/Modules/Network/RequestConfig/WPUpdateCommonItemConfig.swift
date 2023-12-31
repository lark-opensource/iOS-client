//
//  WPUpdateCommonItemConfig.swift
//  LarkWorkplace
//
//  Created by Jiayun Huang on 2022/12/2.
//

import Foundation
import ECOInfra
import SwiftyJSON
import LarkSetting

/// 排序数据更新
struct WPUpdateCommonItemConfig: ECONetworkRequestConfig {
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
        return "/lark/workplace/api/UpdateCommonItem"
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
