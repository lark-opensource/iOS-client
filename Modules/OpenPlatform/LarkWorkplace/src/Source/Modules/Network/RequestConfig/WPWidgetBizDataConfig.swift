//
//  WPWidgetBizDataConfig.swift
//  LarkWorkplace
//
//  Created by Jiayun Huang on 2022/12/1.
//

import Foundation
import ECOInfra
import SwiftyJSON
import LarkSetting

/// Widget业务数据请求
struct WPWidgetBizDataConfig: ECONetworkRequestConfig {
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
        return "/lark/widget/api/GetWidgetContent"
    }

    static var method: ECONetworkHTTPMethod {
        return .POST
    }

    static var initialHeaders: [String: String] {
        /// 由于 widget 服务目前正在推下线，并且这一块服务端代码很久没改动了，怕改动引起的风险
        /// 所以服务端用 rust 在 header 里加 x-lgw-locale 和 x-lgw-locale 替换 Locale、Lark-Version、Os 的逻辑没在 widget 服务里修改
        /// 因此客户端这个接口 header 里需要把这几个参数补上
        return WPGeneralRequestConfig.initialHeaders.merging([
            "Locale": WorkplaceTool.curLanguage(),
            "Lark-Version": WorkplaceTool.appVersion,
            "Os": "ios"
        ]) { $1 }
    }

    static var middlewares: [ECONetworkMiddleware] {
        return WPGeneralRequestConfig.middlewares
    }
}
