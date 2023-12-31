//
//  OpenPluginWiFi.swift
//  LarkOpenApis
//
//  Created by yi on 2021/2/5.
//

import Foundation
import UIKit
import NetworkExtension
import SystemConfiguration.CaptiveNetwork
import CoreLocation
import LarkOpenPluginManager
import LarkOpenAPIModel
import LarkOPInterface
import TTReachability
import ECOProbe
import LarkSetting
import LarkFeatureGating
import LarkCoreLocation
import LarkContainer
import OPFoundation

enum OpenWiFiStatus : UInt {

    case unknown = 0 //未知状态

    case on = 1 //打开状态

    case off = 2 //关闭状态
}

struct OpenNetworkTypeOptions: OptionSet {
    let rawValue: Int
    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static let wifi = OpenNetworkTypeOptions(rawValue: 1 << 0)
    static let fourthGenration = OpenNetworkTypeOptions(rawValue: 1 << 1)
    static let thirdGenration = OpenNetworkTypeOptions(rawValue: 1 << 2)
    static let secondGenration = OpenNetworkTypeOptions(rawValue: 1 << 3)
    static let mobile = OpenNetworkTypeOptions(rawValue: 1 << 4)
}

final class OpenPluginWiFi: OpenBasePlugin {
    
    @FeatureGatingValue(key: "openplatform.api.pluginmanager.extension.enable")
    var apiExtensionEnable: Bool

    lazy var overseaWifiAPIOffline: Bool = {
        userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.api.enable.wifi.oversea.offline")
    }()
    static let currentOsVersionNumber = Float(UIDevice.current.systemVersion)
    static let channelName = Bundle.main.infoDictionary?["CHANNEL_NAME"] as? String
    /// 只考虑网络的是否连接WIFI，不考虑网络连接的是否通畅。
    static let reachability = TTReachability.forInternetConnection()


    /// 定位权限相关
    @InjectedSafeLazy var locationAuth: LocationAuthorization // Global
    /// wifi信息缓存
    struct WifiInfoCache {
        let wifiInfo: OpenPluginGetConnectedWifiResponse
        let timeInterval: TimeInterval
        
        init(wifiInfo: OpenPluginGetConnectedWifiResponse,
             timeInterval: TimeInterval = Date().timeIntervalSince1970) {
            self.wifiInfo = wifiInfo
            self.timeInterval = timeInterval
        }
    }
    
    private var _wifiInfo: WifiInfoCache?
    private let wifiInfoSemaphore = DispatchSemaphore(value: 1)
    
    var wifiInfo: WifiInfoCache? {
        set {
            wifiInfoSemaphore.wait()
            _wifiInfo = newValue
            wifiInfoSemaphore.signal()
        }
        get {
            let result: WifiInfoCache?
            wifiInfoSemaphore.wait()
            result = _wifiInfo
            wifiInfoSemaphore.signal()
            return result
        }
    }
    
  
    lazy var netWorkIOQueue = DispatchQueue(label: "com.bytedance.op.networkIOQueue", attributes: .init(rawValue: 0))

    func getWifiStatus(context: OpenAPIContext, callback: (OpenAPIBaseResponse<OpenAPIGetWifiStatusResult>) -> Void) {

        do {
            let status = try getWifiStatus()
            if status == OpenWiFiStatus.unknown {
                context.apiTrace.error("wifi status is unknown");
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("wifi status is unknown")
                callback(.failure(error: error))
                return
            }
            context.apiTrace.info("get wifi status success, status=\(status)")
            let result = OpenAPIGetWifiStatusResult(status: (status == OpenWiFiStatus.on ? "on" : "off"))
            callback(.success(data: result))
        } catch {
            context.apiTrace.error("getWifiStatus throw error: \(error)");
            let callBackErr = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                .setMonitorMessage(error.localizedDescription)
            callback(.failure(error:callBackErr))
        }
    }

    func getWifiStatus() throws -> OpenWiFiStatus {
        var status = OpenWiFiStatus.unknown
        let type = networkType()
        if (type & OpenNetworkTypeOptions.wifi.rawValue) != 0 {
            status = OpenWiFiStatus.on
        } else {
            /**
             原理解释:
             AWDL : Apple Wireless Direct Link
             awdl0 在没有开启Wifi时只有1个，用于两个设备的P2P直连
             awdl0 在开启Wifi后有2个，后者可用于通过Wifi的通道进行AWDL通信

             https://medium.com/@mariociabarra/wifried-ios-8-wifi-performance-issues-3029a164ce94

             What is AWDL?c
             AWDL (Apple Wireless Direct Link) is a low latency/high speed WiFi peer-to peer-connection Apple uses for everywhere you’d expect: AirDrop, GameKit (which also uses Bluetooth), AirPlay, and perhaps elsewhere. It works using its own dedicated network interface, typically “awdl0".

             While some services, like Instant HotSpot, Bluetooth Tethering (of course), and GameKit advertise their services over Bluetooth SDP, Apple decided to advertise AirDrop over WiFi and inadvertently destroyed WiFi performance for millions of Yosemite and iOS 8 users.

             How does AWDL work?
             Since the iPhone 4, the iOS kernels have had multiple WiFi interfaces to 1 WiFi Broadcom hardware chip.

             en0 — primary WiFi interface
             ap1 — access point interface used for WiFi tethering
             awdl0 — Apple Wireless Direct Link interface (since iOS 7?)

             By having multiple interfaces, Apple is able to have your standard WiFi connection on en0, while still broadcasting, browsing, and resolving peer to peer connections on awdl0 (just not well).

             2 Channels at the same time!
             At any one time, the wifi chip can only communicate at one frequency. Thus, both interfaces would need to be on the same channel when attempting to use both interfaces at the same time. This typically works well when 2 devices are near each other, as they are more than likely connected to the same access point using the same channel.

             I did do some tests having 2 devices connected to different channels (one 5ghz and one 2.4ghz) and they were still able to AirDrop successfully (impressive), albeit with obvious transfer chunking and at about 1/2 the normal transfer rate when both devices are on the same channel.

             */

            // https://developer.apple.com/forums/thread/109355
            var ifaddr : UnsafeMutablePointer<ifaddrs>? = nil

            try OPSensitivityEntry.getifaddrs(forToken: .larkOpenCommonPluginsOpenPluginBluetoothManagerGetWifiStatus, ifad: &ifaddr)
            
            if getifaddrs(&ifaddr) == 0 {
                guard let firstAddr = ifaddr else { return OpenWiFiStatus.unknown }

                var awdl0Count = 0
                for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
                    let flags = Int32(ptr.pointee.ifa_flags)
                    // IFF_UP 表示接口开启
                    if (flags & (IFF_UP)) == IFF_UP,
                       // try to fix https://slardar.bytedance.net/node/app_detail/?aid=1161&os=iOS&region=cn&lang=zh#/abnormal/detail/crash/129c6cd9c1adc6353f94903a5c737a6e?params=%7B%22token%22%3A%22%22%2C%22token_type%22%3A0%2C%22crash_time_type%22%3A%22insert_time%22%2C%22start_time%22%3A1662721860%2C%22end_time%22%3A1663326660%2C%22granularity%22%3A86400%2C%22filters_conditions%22%3A%7B%22type%22%3A%22and%22%2C%22sub_conditions%22%3A%5B%5D%7D%2C%22ios_issue_id_version%22%3A%22v2%22%2C%22event_index%22%3A1%7D
                        let infaName = ptr.pointee.ifa_name {
                        let interfaceName =  String(cString: infaName)
                        // AWDL : Apple Wireless Direct Link
                        if interfaceName == "awdl0" {
                            awdl0Count = awdl0Count + 1
                        }
                    }
                }
                freeifaddrs(ifaddr)
                if awdl0Count < 2 {
                    status = OpenWiFiStatus.off
                } else {
                    status = OpenWiFiStatus.on
                }
            } else {
                status = OpenWiFiStatus.unknown
            }
        }
        return status
    }
    
    func onGetWifiList(callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        callback(.success(data: nil))
    }

    func offGetWifiList(callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        callback(.success(data: nil))
    }

    func getWifiList(context: OpenAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        // 需要向Apple申请权限才能支持，目前先返回不支持。
        callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.unable).setOuterMessage("system not support")))
    }


    func networkType() -> Int {
        var type = 0

        if TTReachability.is2GConnected() {
            type |= OpenNetworkTypeOptions.secondGenration.rawValue
            type |= OpenNetworkTypeOptions.mobile.rawValue
        }
        if TTReachability.is3GConnected() {
            type |= OpenNetworkTypeOptions.thirdGenration.rawValue
            type |= OpenNetworkTypeOptions.mobile.rawValue
        }
        if TTReachability.is4GConnected() {
            type |= OpenNetworkTypeOptions.fourthGenration.rawValue
            type |= OpenNetworkTypeOptions.mobile.rawValue
        }
        if innerIsWifiConnected() {
            type |= OpenNetworkTypeOptions.wifi.rawValue
        }
        return type
    }

    private func innerIsWifiConnected() -> Bool {
        if OpenPluginWiFi.channelName == "local_test" || OpenPluginWiFi.channelName == "dev" {
            let isDebugDisbaleWIFI = LSUserDefault.standard.getBool(forKey: "debug_disable_network")
            if isDebugDisbaleWIFI {
                return false
            }
        }
        return OpenPluginWiFi.reachability.currentReachabilityStatus() == .ReachableViaWiFi
    }
    
    enum APIName: String {
        case getConnectedWifi
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "getWifiStatus", pluginType: Self.self, resultType: OpenAPIGetWifiStatusResult.self) { (this, _, context, callback) in
            
            this.getWifiStatus(context: context, callback: callback)
        }
        registerInstanceAsyncHandler(for: "onGetWifiList", pluginType: Self.self) { (this, _, context, callback) in
            
            this.onGetWifiList(callback: callback)
        }
        registerInstanceAsyncHandler(for: "offGetWifiList", pluginType: Self.self) { (this, _, context, callback) in
            
            this.offGetWifiList(callback: callback)
        }
        registerInstanceAsyncHandler(for: "getWifiList", pluginType: Self.self) { (this, _, context, callback) in
            
            this.getWifiList(context: context, callback: callback)
        }
        if apiExtensionEnable {
            registerAsync(
                for: APIName.getConnectedWifi.rawValue,
                registerInfo: .init(
                    pluginType: Self.self,
                    paramsType: OpenPluginGetConnectedWifiRequest.self,
                    resultType: OpenPluginGetConnectedWifiResponse.self
                ), extensionInfo: .init(
                    type: OpenAPIWifiExtension.self,
                    defaultCanBeUsed: true))
            { this in
                Self.getConnectedWifiExtension(this)
            }
        } else {
            registerInstanceAsyncHandler(for: APIName.getConnectedWifi.rawValue, pluginType: Self.self, paramsType: OpenPluginGetConnectedWifiRequest.self, resultType: OpenPluginGetConnectedWifiResponse.self) { this, params, context, callback in
                this.getConnectedWifi(params: params, context: context, callback: callback)
            }
        }
    }
}

