//
//  WPUpdateBadgeStatusConfig.swift
//  LarkWorkplace
//
//  Created by Jiayun Huang on 2022/12/3.
//

import Foundation
import ECOInfra
import SwiftyJSON
import LarkSetting

/// 更改 badge 开关状态
struct WPUpdateBadgeStatusConfig: ECONetworkRequestConfig {
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
        return DomainSettingManager.shared.currentSetting[.mpConfig]?.first
    }

    static var path: String {
        return "/open-apis/mina/SyncClientAuth"
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
