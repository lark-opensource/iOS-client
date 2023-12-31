//
//  GetNetworkTypeHandler.swift
//  Lark
//
//  Created by ChalrieSu on 2018/4/12.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import LKCommonsLogging
import WebBrowser

class GetNetworkTypeHandler: JsAPIHandler {
    static let logger = Logger.log(GetNetworkTypeHandler.self, category: "Module.JSSDK")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        /// 等待和小程序融合时重构，网络方法放在GeoLocationHandler不合理
        let status = GeoLocationHandler.networkStatus()
        callback.callbackSuccess(param: ["result": status,
                                         "networkType": status])
    }
}
