//
//  GetGatewayIPHandler.swift
//  LarkWeb
//
//  Created by 李论 on 2019/12/12.
//

import UIKit
import LKCommonsLogging
import Foundation
import CoreLocation
import WebBrowser

class GetGatewayIPHandler: JsAPIHandler {
    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        if GeoLocationHandler.networkStatus() != "wifi" {
            /// 没连接Wi-Fi要回调
            callback.callbackFailure(param: NewJsSDKErrorAPI.GetGatewayIP.noWiFiConnect.description())
            return
        }

        let ipInfo = LarkWebNetworkHelper.gatewayInfo()
        /// 加个日志辅助定位问题，打一下网络类型和wifiinfo
        if ipInfo.code != 0 {
            GetGatewayIPHandler.logger.info(GeoLocationHandler.networkStatus())
            callback.callbackFailure(param: NewJsSDKErrorAPI.GetGatewayIP.noWiFiInfo.description(with: ipInfo.errMsg))
            return
        }
        let wifiInfo = ["ip": ipInfo.routerIP]
        /// 回调info
        callback.callbackSuccess(param: wifiInfo)
    }

    var needAuthrized: Bool {
        return true
    }

    static let logger = Logger.log(GetGatewayIPHandler.self, category: "Module.JSSDK")
}
