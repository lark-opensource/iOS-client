//
//  WifiChecker.swift
//  Pods
//
//  Created by tujinqiu on 2019/8/11.
//

import Foundation
import SystemConfiguration.CaptiveNetwork
import Reachability
import LKCommonsLogging
import LarkOPInterface
import LarkSetting
import NetworkExtension
import OPFoundation
import LarkContainer

//  FIXME：不要耦合判断开不开Wi-Fi的逻辑，一并上传即可，逻辑放入后端
class WifiChecker {
    private static let logger = Logger.oplog(WifiChecker.self, category: "WifiChecker")

    typealias WhenNetworkChangedCallback = (WIFIInfo) -> Void

    private var reachability: Reachability?
    private var whenNetworkChanged: WhenNetworkChangedCallback?
    private var lastSSID: String?
    private var lastBSSID: String?
    private var resolver: UserResolver
    
    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func start(whenNetworkChanged: WhenNetworkChangedCallback?) {
        self.whenNetworkChanged = whenNetworkChanged
        if reachability == nil {
            reachability = Reachability()
        }
        if let reach = reachability {
            reach.notificationCenter.addObserver(self, selector: #selector(onNetworkChanged(_:)), name: Notification.Name.reachabilityChanged, object: nil)
            do {
                try reach.startNotifier()
            } catch {
                WifiChecker.logger.error("reachability startNotifier fail")
            }
        }
    }

    func stop() {
        if let reach = reachability {
            reach.stopNotifier()
            reach.notificationCenter.removeObserver(self)
        }
    }

    // 不要传上次的wifi信息
    func getWifiInfoSync() -> WIFIInfo? {
        let (SSID, BSSID) = getCurrenWifiInfoSync()
        lastSSID = SSID
        lastBSSID = BSSID
        return WIFIInfo(SSID: SSID, BSSID: BSSID, lastSSID: nil, lastBSSID: nil)
    }
    
    func getWifiInfo(completion: @escaping (WIFIInfo?) -> Void) {
        let monitorEvent = MonitorEvent(name: MonitorEvent.terminalinfo_wifi)
        if #available(iOS 14.0, *) {
            WifiChecker.logger.info("apple recommend get wifi info")
            do {
                try OPSensitivityEntry.fetchCurrent(forToken: .openPlatformWifiCheckerGetWifiInfoNEHotspotNetwork) { [weak self](network) in
                    if let network = network {
                        WifiChecker.logger.info("get wifi info success")
                        monitorEvent.addSuccess().flush()
                        let clockInWifi = WIFIInfo(SSID: network.ssid, BSSID: MacAddressFormat().format(network.bssid), lastSSID: nil, lastBSSID: nil)
                        self?.lastSSID = network.ssid
                        self?.lastBSSID = network.bssid
                        completion(clockInWifi)
                    } else {
                        monitorEvent.addFail().addError(2, "wifi null").flush()
                        WifiChecker.logger.error("get wifi info fail")
                        completion(nil)
                    }
                }
            } catch {
                WifiChecker.logger.error("NEHotspotNetwork fetchCurrent throw error: \(error)")
                completion(nil)
            }
            
        } else if let wifiInfo = self.getWifiInfoSync() {
            if wifiInfo != nil {
                WifiChecker.logger.info("get wifi info success")
                monitorEvent.addSuccess().flush()
            } else {
                WifiChecker.logger.error("get wifi info fail")
                monitorEvent.addFail().addError(2, "wifi null").flush()
            }
            completion(wifiInfo)
        }
    }

    private func getCurrenWifiInfoSync() -> (String?, String?) {
        WifiChecker.logger.info("get wifi info by CNCopyCurrentNetworkInfo")
        guard let cfas: NSArray = CNCopySupportedInterfaces() else {
            return (nil, nil)
        }
        var SSID: String?
        var BSSID: String?
        for cfa in cfas {
            do {
                let cfDic = try OPSensitivityEntry
                    .CNCopyCurrentNetworkInfo(forToken: .openPlatformWifiCheckerGetCurrenWifiInfoSyncCNCopyCurrentNetworkInfo,
                                              interfaceName: cfa as! CFString)
                if let dic = CFBridgingRetain(cfDic) {
                    if let ssid = dic["SSID"] as? String {
                        SSID = ssid
                    }
                    if let bssid = dic["BSSID"] as? String {
                        BSSID = bssid
                    }
                }
            } catch {
                WifiChecker.logger.error("CNCopyCurrentNetworkInfo throw error: \(error)")
            }
        }
        return (SSID, BSSID)
    }

    // 只有在网络变化的时候需要上传上次的wifi信息
    @objc
    private func onNetworkChanged(_ notification: Notification) {
        guard !resolver.fg.dynamicFeatureGatingValue(with: "attendance.top_speed_clock_in.forbid_bssid") else {
            return
        }
        let (SSID, BSSID) = getCurrenWifiInfoSync()
        if let reach = notification.object as? Reachability,
            reach.connection == .wifi || reach.connection == .cellular {
            let wifiInfo = WIFIInfo(SSID: SSID, BSSID: BSSID, lastSSID: lastSSID, lastBSSID: lastBSSID)
            whenNetworkChanged?(wifiInfo)
        }
        lastSSID = SSID
        lastBSSID = BSSID
    }

    deinit {
        stop()
    }
}
