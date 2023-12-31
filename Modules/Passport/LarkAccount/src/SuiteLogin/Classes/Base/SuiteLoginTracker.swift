//
//  SuiteLoginTracker.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/9/2.
//

import Foundation
import LKCommonsLogging
import LKCommonsTracker

class SuiteLoginTracker {

    #if DEBUG
    static let logger = Logger.plog(SuiteLoginTracker.self, category: "SuiteLoginTracker")
    #endif

    static func track(_ name: String, params: [AnyHashable: Any] = [:]) {
        #if DEBUG
        logger.debug("track info event = \(name) params = \(params)")
        #endif
        Tracker.post(TeaEvent(name, params: params))
    }

    /// 创建通用的点击事件业务埋点参数 map
    static func makeCommonViewParams(flowType: String, data: [String: Any]? = nil) -> [AnyHashable: Any] {
        var params: [AnyHashable: Any] = ["passport_appid": Self.appID,
                                          "tracking_code": "none",
                                          "template_id": "none",
                                          "utm_from": "none"]

        params["flow_type"] = flowType

        if let others = data {
            others.forEach { (key, value) in
                params[key] = value
            }
        }

        return params
    }

    /// 创建通用的点击事件业务埋点参数 map
    static func makeCommonClickParams(flowType: String, click: String, target: String, data: [String: Any]? = nil) -> [AnyHashable: Any] {
        var params: [AnyHashable: Any] = ["passport_appid": Self.appID,
                                          "tracking_code": "none",
                                          "template_id": "none",
                                          "utm_from": "none"]

        params["flow_type"] = flowType
        params["click"] = click
        params["target"] = target

        if let others = data {
            others.forEach { (key, value) in
                params[key] = value
            }
        }

        return params
    }

    static let appID = "1"
}
