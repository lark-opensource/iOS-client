//
//  WPShareBlockItemByMessageCardConfig.swift
//  LarkWorkplace
//
//  Created by ByteDance on 2023/5/20.
//

import Foundation
import ECOInfra
import LarkWorkplaceModel
import LarkSetting

struct WPShareBlockItemByMessageCardConfig: ECONetworkRequestConfig {
    typealias ParamsType = WPShareBlockByMessageCardRequestParams
    typealias ResultType = WPResponse<WPBlockShareStatus>

    typealias RequestSerializer = ECORequestCodableSerializer<WPShareBlockByMessageCardRequestParams>
    typealias ResponseSerializer = ECOResponseCodableSerializer<WPResponse<WPBlockShareStatus>>

    static var requestSerializer = RequestSerializer()
    static var responseSerializer = ResponseSerializer()

    static var domain: String? {
        return DomainSettingManager.shared.currentSetting[.openAppcenter3]?.first
    }

    static var path: String {
        return "/lark/workplace/api/ShareBlockItemByMessageCard"
    }

    static var method: ECONetworkHTTPMethod {
        return .POST
    }

    static var initialHeaders: [String : String] {
        return WPGeneralRequestConfig.initialHeaders
    }

    static var middlewares: [ECONetworkMiddleware] {
        return WPGeneralRequestConfig.middlewares
    }
}
