//
//  GetInterfaceHandler.swift
//  Lark
//
//  Created by ChalrieSu on 2018/4/12.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import SystemConfiguration.CaptiveNetwork
import LKCommonsLogging
import WebBrowser
import OPFoundation

class GetInterfaceHandler: JsAPIHandler {
    static let logger = Logger.log(GetInterfaceHandler.self, category: "Module.JSSDK")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        if let wifiInfo = GetInterfaceHandler.getWifiInfo() {
            callback.callbackSuccess(param: ["code": 0,
                                             "ssid": wifiInfo.ssid,
                                             "macIp": wifiInfo.mac])
        } else {
            callback.callbackSuccess(param: ["code": 1])
        }
    }

    //获取 WiFi 信息
    static func getWifiInfo() -> (ssid: String, mac: String)? {
        if let cfas: NSArray = CNCopySupportedInterfaces() {
            for cfa in cfas {
                // 这里从Any转CFString只能使用as!转，官方有说明，这种转换在runtime一定会成功。
                // https://forums.developer.apple.com/thread/11171
                // swiftlint:disable force_cast
                var wifiInfo: (ssid: String, mac: String)? = nil
                do {
                    let cfDic = try OPSensitivityEntry.CNCopyCurrentNetworkInfo(forToken: .jssdkGetInterfaceHandlerGetWifiInfo, interfaceName: cfa as! CFString)
                    if let dic = CFBridgingRetain(cfDic) {
                        if let ssid = dic["SSID"] as? String, let bssid = dic["BSSID"] as? String {
                            wifiInfo = (ssid, bssid)
                        }
                    }
                } catch {
                    GetInterfaceHandler.logger.error("CNCopyCurrentNetworkInfo throw error: \(error)")
                }
                if let wifiInfo = wifiInfo {
                    return wifiInfo
                }
                // swiftlint:enable force_cast
            }
        }
        GetInterfaceHandler.logger.error("getWifiInfo error, has no wifi info form CNCopySupportedInterfaces and CNCopyCurrentNetworkInfo")
        return nil
    }
}
