//
//  WPGeneralRequestConfig.swift
//  LarkWorkplace
//
//  Created by Jiayun Huang on 2022/11/25.
//

import Foundation
import LarkUIKit
import ECOInfra
import LarkSetting
import LKCommonsLogging

enum WPGeneralRequestConfig {
    
    static var initialHeaders: [String: String] {
        return [
            "Platform": Display.pad ? "ipad" : "iphone",
            "Os": "iOS"
        ]
    }

    static var middlewares: [ECONetworkMiddleware] {
        return [
            WPRequestInjectMiddleware(),
            WPRequestTraceMiddleware(),
            WPTimeoutSettingMiddleware(),
            WPNetworkMonitorMiddleware()
        ]
    }

    /// 已有接口通用的 parameters，6.6 版本以后续新增的接口不需要带上这两个字段
    static var legacyParameters: [String: String] {
        return [
            "larkVersion": WPUtils.appVersion,
            "locale": WorkplaceTool.curLanguage()
        ]
    }
}
