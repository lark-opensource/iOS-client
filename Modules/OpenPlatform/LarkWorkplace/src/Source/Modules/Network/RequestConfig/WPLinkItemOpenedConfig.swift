//
//  WPLinkItemOpenedConfig.swift
//  LarkWorkplace
//
//  Created by Shengxy on 2023/4/13.
//

import Foundation
import ECOInfra
import LarkWorkplaceModel
import SwiftyJSON
import LarkSetting

/// Config struct of `LinkItemOpened` http request.
struct WPLinkItemOpenedConfig: ECONetworkRequestConfig {
    typealias ParamsType = WPCustomLinkOpenedRequestParams
    typealias ResultType = WPResponse<JSON> // no `data` field, JSON is only for placeholder

    typealias RequestSerializer = ECORequestCodableSerializer<WPCustomLinkOpenedRequestParams>
    typealias ResponseSerializer = ECOResponseCodableSerializer<WPResponse<JSON>>

    static var requestSerializer = RequestSerializer()
    static var responseSerializer = ResponseSerializer()

    static var domain: String? {
        return DomainSettingManager.shared.currentSetting[.openAppcenter3]?.first
    }

    static var path: String {
        return "/lark/workplace/api/recent/LinkItemOpened"
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
