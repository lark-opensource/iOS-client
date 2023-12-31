//
//  WPGetAppBadgeSettingConfig.swift
//  LarkWorkplace
//
//  Created by Jiayun Huang on 2022/12/3.
//

import Foundation
import ECOInfra
import SwiftyJSON
import LarkSetting

/// 批量拉取某用户的 badge 开关设置
struct WPGetAppBadgeSettingConfig: ECONetworkRequestConfig {
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

    static var domain: String? {
        return DomainSettingManager.shared.currentSetting[.openAppcenter3]?.first
    }

    static var path: String {
        return "/lark/app_badge/api/PullAppBadgeSetting"
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
