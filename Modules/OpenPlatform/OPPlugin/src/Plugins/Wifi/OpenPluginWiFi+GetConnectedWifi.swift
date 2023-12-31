//
//  OpenPluginWiFi+GetConnectedWiFI.swift
//  OPPlugin
//
//  Created by 张旭东 on 2022/9/7.
//

import CoreLocation
import Foundation
import LarkFeatureGating
import LarkOpenAPIModel
import LarkOpenPluginManager
import LarkSetting
import NetworkExtension
import SystemConfiguration.CaptiveNetwork
import OPFoundation
import LarkCoreLocation

extension OpenPluginWiFi {
    func getConnectedWifi(
        params: OpenPluginGetConnectedWifiRequest,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenPluginGetConnectedWifiResponse>) -> Void)
    {
        pr_getConnectedWifi(params: params, context: context, wifiExtension: nil, callback: callback)
    }
    
    func getConnectedWifiExtension(
        params: OpenPluginGetConnectedWifiRequest,
        context: OpenAPIContext,
        wifiExtension: OpenAPIWifiExtension,
        callback: @escaping (OpenAPIBaseResponse<OpenPluginGetConnectedWifiResponse>) -> Void)
    {
        pr_getConnectedWifi(params: params, context: context, wifiExtension: wifiExtension, callback: callback)
    }
    
    func pr_getConnectedWifi(
        params: OpenPluginGetConnectedWifiRequest,
        context: OpenAPIContext,
        wifiExtension: OpenAPIWifiExtension?,
        callback: @escaping (OpenAPIBaseResponse<OpenPluginGetConnectedWifiResponse>) -> Void)
    {
        context.apiTrace.info("getConnectedWifi enter params: < cacheTimeout: \(params.cacheTimeout) > overseaWifiAPIOffline: \(overseaWifiAPIOffline)")
        /// 海外下线开关
        guard !overseaWifiAPIOffline else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                .setErrno(OpenAPICommonErrno.unable)
                .setOuterMessage("Invalid API")
            callback(.failure(error: error))
            return
        }
        let monitor = OpenAPIGetConnectedWifiMonitor()
        if let wifiExtension = wifiExtension {
            monitor.set(wifiExtension)
        } else {
            monitor.set(context: context)
        }
        /// 缓存逻辑
        let cacheTimeout = params.cacheTimeout
        // 如果cacheTimeout小于0或大于60s，则不使用缓存
        if cacheTimeout > 0, cacheTimeout <= 60,
           let cache = wifiInfo,
           Int(NSDate().timeIntervalSince1970 - cache.timeInterval) < cacheTimeout
        {
            let wifiInfo = cache.wifiInfo
            context.apiTrace.info("getConnectedWifi byCache,wifiInfo=\(wifiInfo)")
            monitor.set(tool: .cache)
            monitor.reportSuccess()
            callback(.success(data: wifiInfo))
            return
        }
        /// plugin 意外释放回调
        let pluginReleasedCallback = {
            let msg = "getConnectedWifi callback but plugin released"
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setErrno(OpenAPICommonErrno.internalError)
                .setMonitorMessage(msg)
            callback(.failure(error: error))
        }
        /// iOS 13以上检测地理位置回调
        let noLocationAuthCallback = {
            monitor.reportFailed(reason: .noLocationAuthorization)
            let msg = "getConnectedWifi iOS Version: \(UIDevice.current.systemVersion), locationAuth: \(false)"
            context.apiTrace.error(msg)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                .setErrno(OpenAPICommonErrno.systemAuthDeny)
                .setOuterMessage("have no location auth")
                .setMonitorMessage(msg)
            callback(.failure(error: error))
        }
        /// 未连接wifi 回调
        let noConnectedWifiCallback = {
            monitor.reportFailed(reason: .noConnectedWifi)
            let error = OpenAPIError(code: GetConnectedWifiErrorCode.invalidSsid)
                .setErrno(OpenAPIWifiErrno.notConnected)
            callback(.failure(error: error))
        }
        /// invalidSSID 回调
        let invalidSSIDCallbck = {
            let error = OpenAPIError(code: GetConnectedWifiErrorCode.invalidSsid)
                .setErrno(OpenAPIWifiErrno.invalid)
            monitor.reportFailed(reason: .unknow)
            callback(.failure(error: error))
        }
        
        /// 调用获取wifi信息方法的回调
        let fetchInfoCallback: (OpenPluginGetConnectedWifiResponse?, Error?) -> Void = { [weak self] result, error in
            guard let self = self else {
                pluginReleasedCallback()
                return
            }
            if let error = error {
                let msg = "getConnectedWifi callback error: \(error)"
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setErrno(OpenAPICommonErrno.internalError)
                    .setMonitorMessage(msg)
                callback(.failure(error: error))
                return
            }
            /// 获取成功
            if let result = result {
                context.apiTrace.info("fetchWifiInfo success wifiInfo: \(result)")
                self.wifiInfo = WifiInfoCache(wifiInfo: result)
                monitor.reportSuccess()
                callback(.success(data: result))
                return
            }
            // iOS 12 以上 获取wifiInfo 需要 地理位置授权 & 精确位置信息授权
            if #available(iOS 13.0, *), !self.isHasLocationAuth {
                noLocationAuthCallback()
                return
            }
            
            // 校验当前网络类型
            let currentReachabilityStatus = OpenPluginWiFi.reachability.currentReachabilityStatus()
            if currentReachabilityStatus == .ReachableViaWiFi {
                context.apiTrace.error("getConnectedWifi fail, current is wifi, networkType=\(currentReachabilityStatus)")
                invalidSSIDCallbck()
            } else {
                context.apiTrace.error("getConnectedWifi fail, current is not wifi, networkType:\(currentReachabilityStatus)")
                noConnectedWifiCallback()
            }
        }
        /*
         获取Wi-Fi信息需要下面权限中的任意一个
         1. iOS 13+ application is using CoreLocation API and has user's authorization to access precise location.
         2. application has used NEHotspotConfiguration API to configure the current Wi-Fi network.
         3. application has active VPN configurations installed.
         4. application has active NEDNSSettingsManager configuration installed.
         目前可确定的是飞书只有定位权限。所以这里先请求权限，然后尝试获取wifi信息，如果失败再做失败的归因。
         */
        if #available(iOS 13.0, *) {
            let callback: LocationAuthorizationCallback = {  [weak self] _ in
                guard let self = self else {
                    pluginReleasedCallback()
                    return
                }
                self.fetchWifiInfo(context: context,
                                   monitor: monitor,
                                   complete: fetchInfoCallback)
            }
            locationAuth.requestWhenInUseAuthorization(forToken: OPSensitivityEntryToken.openPluginWiFiGetConnectedWifi.psdaToken, complete: callback)
        } else {
            fetchWifiInfo(context: context,
                          monitor: monitor,
                          complete: fetchInfoCallback)
        }
    }
    
    private func fetchWifiInfo(context: OpenAPIContext,
                               monitor: OpenAPIGetConnectedWifiMonitor,
                               complete: @escaping (OpenPluginGetConnectedWifiResponse?,Error?) -> Void)
    {
        if #available(iOS 14.0, *) {
            monitor.set(tool: .NEHotspotNetworkFetchCurrent)
            /*
             This method returns SSID, BSSID and security type of the current Wi-Fi network when the
             *   requesting application meets one of following 4 requirements -.
             *   1. application is using CoreLocation API and has user's authorization to access precise location.
             *   2. application has used NEHotspotConfiguration API to configure the current Wi-Fi network.
             *   3. application has active VPN configurations installed.
             *   4. application has active NEDNSSettingsManager configuration installed.
             *   An application will receive nil if it fails to meet any of the above 4 requirements.
             *   An application will receive nil if does not have the "com.apple.developer.networking.wifi-info" entitlement.
             */
            do {
                try OPSensitivityEntry.fetchCurrent(forToken: .openPluginWiFiGetConnectedWifiNEHotspotNetwork,
                                                   completionHandler: { network in
                                                       context.apiTrace.info("getConnectedWifi NEHotspotNetwork.fetchCurrent callbask netWork is :\(String(describing: network))")
                                                       if let network = network {
                                                           complete(OpenPluginGetConnectedWifiResponse(
                                                               BSSID: MacAddressFormat().format(network.bssid),
                                                               SSID: network.ssid,
                                                               secure: network.isSecure,
                                                               signalStrength: network.signalStrength), nil)
                                                       } else {
                                                           complete(nil, nil)
                                                       }
                                                   })
            } catch {
                complete(nil, error)
            }
            
            return
        }
    
        monitor.set(tool: .CNCopySupportedInterfaces)
        context.apiTrace.info("getConnectedWifi use CNCopyCurrentNetworkInfo")
        /// CNCopySupportedInterfaces会有概率卡住线程的情况,将该逻辑放在单独的线程中执行;
        netWorkIOQueue.async {
            do {
                guard let wifiInterfaces = CNCopySupportedInterfaces() as? [String] else {
                    context.apiTrace.info("getConnectedWifi use CNCopyCurrentNetworkInfo failed")
                    complete(nil,nil)
                    return
                }
             
                for interfaceName in wifiInterfaces {
                    let cfwifiInfoDict = try OPSensitivityEntry.CNCopyCurrentNetworkInfo(forToken: .openPluginWiFiGetConnectedWifiCNCopyCurrentNetworkInfo, interfaceName: interfaceName as CFString)
                    guard let wifiInfoDict = cfwifiInfoDict as? [String: AnyObject] else {
                        continue
                    }
                    context.apiTrace.info("getConnectedWifi use CNCopyCurrentNetworkInfo interfaceName: \(interfaceName) result: \(wifiInfoDict)")
                    let ssid = wifiInfoDict[(kCNNetworkInfoKeySSID as NSString) as String] as? String
                    let bssid = wifiInfoDict[(kCNNetworkInfoKeyBSSID as NSString) as String] as? String
                    /*
                     1. application is using CoreLocation API and has the user's authorization to access location.
                     2. application has used the NEHotspotConfiguration API to configure the current Wi-Fi network.
                     3. application has active VPN configurations installed.
                     4. application has active NEDNSSettingsManager configurations installed.

                     - An application that is linked against iOS 12.0 SDK and above must have the "com.apple.developer.networking.wifi-info" entitlement.
                     - An application will receive a pseudo network information if it is linked against an SDK before iOS 13.0, and if it fails to meet any of the，above requirements. Pseudo network information will contain "Wi-Fi" SSID and "00:00:00:00:00:00" BSSID. For China region, the SSID will be "WLAN".
                     - An application will receive NULL if it is linked against iOS 13.0 SDK (or newer), and if it fails to meet any of the above requirements.
                     - On Mac Catalyst platform, to receive current Wi-Fi network information, an application must have "com.apple.developer.networking.wifi-info"
                      entitlement and user's authorization to access location.
                     */
                    if let ssid = ssid,
                       let bssid = bssid,
                       !bssid.isEmpty,
                       bssid != "00:00:00:00:00:00"
                    {
                        complete(OpenPluginGetConnectedWifiResponse(
                            BSSID: MacAddressFormat().format(bssid),
                            SSID: ssid,
                            secure: nil,
                            signalStrength: nil), nil )
                        return
                    }
                }
                complete(nil, nil)
            } catch {
                complete(nil, error)
            }
           
        }
    }
    
    private var isHasLocationAuth: Bool {
        // 校验定位权限
        let authStatus: CLAuthorizationStatus
        let hasFullAccuracyAuth: Bool
        let servicesEnabled = locationAuth.locationServicesEnabled()
        if #available(iOS 14.0, *) {
            let locationManager = CLLocationManager()
            authStatus = locationManager.authorizationStatus
            hasFullAccuracyAuth = locationManager.accuracyAuthorization == .fullAccuracy
        } else {
            authStatus = CLLocationManager.authorizationStatus()
            hasFullAccuracyAuth = true
        }
        let hasAuthorize = servicesEnabled &&
            (authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse) &&
            hasFullAccuracyAuth
        return hasAuthorize
    }
}

/// iOS 调用系统API 获取到的 bssid 可能是这个样子 b8:3a:5a:b4:3:92。当 ":" 中间的是一位时我们需要补0
private struct MacAddressFormat {
    func format(_ macAddress: String) -> String {
        /*
         防止以下情况的转换
         ":1" => "01"
         "1:" => "01"
         "::" => ""
         */
        if macAddress.count <= 1 {
            return macAddress
        }
        let components = macAddress.split(separator: ":")
        guard components.count > 1 else {
            return macAddress
        }
        return components.map { $0.count == 1 ? "0\($0)" : $0 }.joined(separator: ":")
    }
}
