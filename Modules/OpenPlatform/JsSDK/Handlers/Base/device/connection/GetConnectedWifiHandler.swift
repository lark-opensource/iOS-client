//
//  GetConnectedWifiHandler.swift
//  LarkWeb
//
//  Created by 武嘉晟 on 2019/10/31.
//

import CoreLocation
import LKCommonsLogging
import NetworkExtension
import SystemConfiguration.CaptiveNetwork
import WebBrowser
import OPFoundation

class GetConnectedWifiHandler: JsAPIHandler {
    static let log = Logger.log(GetConnectedWifiHandler.self)
    let ssidKey = "SSID"
    let bssidKey = "BSSID"
    let secureKey = "secure"
    let signalStrengthKey = "signalStrength"
    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        if GeoLocationHandler.networkStatus() != "wifi" {
            /// 没连接Wi-Fi要回调
            callback.callbackFailure(param: NewJsSDKErrorAPI.GetConnectedWifi.noWiFiConnect.description())
            return
        }
        let wifiInfo = getWiFiInfo()
        /// iOS13中， 如果没有位置授权的话会导致获取WiFi信息失败，
        /// 详见： https://developer.apple.com/documentation/systemconfiguration/1614126-cncopycurrentnetworkinfo
        if #available(iOS 13.0, *) {
            let status = CLLocationManager.authorizationStatus()
            var hasAuthorize = false
            if status == .authorizedAlways || status == .authorizedWhenInUse {
                hasAuthorize = true
            }
            let bssid = wifiInfo[bssidKey] as? String ?? ""
            if (bssid.isEmpty || bssid == "00:00:00:00:00:00") && !hasAuthorize {
                /// 回调失败 信息是iOS13没有定位权限无法获取Wi-Fi信息
                callback.callbackFailure(param: NewJsSDKErrorAPI.GetConnectedWifi.noLocation.description())
                return
            }
        }
        /// 加个日志辅助定位问题，打一下网络类型和wifiinfo
        if wifiInfo.isEmpty {
            GetConnectedWifiHandler.log.info(GeoLocationHandler.networkStatus())
            callback.callbackFailure(param: NewJsSDKErrorAPI.GetConnectedWifi.noWiFiInfo.description())
            return
        }
        /// 回调info
        callback.callbackSuccess(param: wifiInfo)
    }
}

extension GetConnectedWifiHandler {
    private func getWiFiInfo() -> [String: Any] {
        var wifiInfo: [String: Any] = [String: Any]()
        if let supportedNetworkInterfaces = NEHotspotHelper.supportedNetworkInterfaces(),
            !supportedNetworkInterfaces.isEmpty,
            let net = supportedNetworkInterfaces[0] as? NEHotspotNetwork {
            /// 如果支持新API，用新API
            wifiInfo[ssidKey] = net.ssid
            wifiInfo[bssidKey] = net.bssid
            wifiInfo[secureKey] = net.isSecure
            wifiInfo[signalStrengthKey] = net.signalStrength
            return wifiInfo
        }
        if let cfas: NSArray = CNCopySupportedInterfaces() {
            for cfa in cfas {
                // 这里从Any转CFString只能使用as!转，官方有说明，这种转换在runtime一定会成功。
                // https://forums.developer.apple.com/thread/11171
                // swiftlint:disable force_cast
                let cfDic: CFDictionary?
                do {
                    cfDic = try OPSensitivityEntry.CNCopyCurrentNetworkInfo(forToken: .jssdkGetConnectedWifiHandlerGetConnectedWifiCNCopyCurrentNetworkInfo, interfaceName: cfa as! CFString)
                } catch {
                    GetConnectedWifiHandler.log.error(logId: "CNCopyCurrentNetworkInfo throw error: \(error)")
                    cfDic = nil
                }
                if let dic = CFBridgingRetain(CNCopyCurrentNetworkInfo(cfa as! CFString)) {
                    wifiInfo[ssidKey] = dic[ssidKey] as? String
                    wifiInfo[bssidKey] = dic[bssidKey] as? String
                    wifiInfo[secureKey] = dic[secureKey] as? Bool
                    wifiInfo[signalStrengthKey] = dic[signalStrengthKey] as? Double
                }
                // swiftlint:enable force_cast
            }
        }
        return wifiInfo
    }
}
