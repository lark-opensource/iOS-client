//
//  WPSearchItemByTagCodableConfig.swift
//  LarkWorkplace
//
//  Created by Shengxy on 2023/1/8.
//

import Foundation
import ECOInfra
import LarkWorkplaceModel
import LarkSetting

/// Config struct of `SearchItemByTag` http request.
/// The main difference between `WPSearchItemByTagConfig` and `WPSearchItemByTagCodableConfig` is
/// `WPSearchItemByTagCodableConfig` use `Codable` struct instead of `JSON` object as request parameter type and response data type.
/// `WPSearchItemByTagConfig` could be replaced with `WPSearchItemByTagCodableConfig` when FG related to these two struct is valid to all users.
struct WPSearchItemByTagCodableConfig: ECONetworkRequestConfig {
    typealias ParamsType = WPSearchCategoryAppRequestParams
    typealias ResultType = WPResponse<WPSearchCategoryApp>

    typealias RequestSerializer = ECORequestCodableSerializer<WPSearchCategoryAppRequestParams>
    typealias ResponseSerializer = ECOResponseCodableSerializer<WPResponse<WPSearchCategoryApp>>

    static let requestSerializer = RequestSerializer()
    static let responseSerializer = ResponseSerializer()

    static var domain: String? {
        return DomainSettingManager.shared.currentSetting[.openAppcenter3]?.first
    }

    static var path: String {
        return "/lark/workplace/api/SearchItemByTag"
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
