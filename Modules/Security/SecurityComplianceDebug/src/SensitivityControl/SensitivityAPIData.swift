//
//  SensitivityAPIData.swift
//  SecurityComplianceDebug
//
//  Created by yifan on 2022/11/29.
//

import CoreMotion
import CoreLocation
#if canImport(CoreTelephony)
import CoreTelephony
#endif
import Contacts
import LarkSensitivityControl
import LarkSecurityComplianceInfra
import LocalAuthentication
import LarkEMM
import SystemConfiguration.CaptiveNetwork
import UniverseDesignToast
import CFNetwork
import EventKit
import AVFoundation
import Photos
import ReplayKit
import CoreBluetooth
import NetworkExtension
import PhotosUI

struct SensitivityAPIData {
    let token = Token(kTokenAvoidInterceptIdentifier)

    struct SectionData {
        var type: String
        var apiDatas: [APIData]
    }

    struct APIData {
        var title: String
        var action: (Int, UIView) -> Void = { _, _ in }
    }

    func build() -> [SectionData] {
        var items = [SectionData]()
        items.append(buildCrash())
        items.append(monitorFuse())
        items.append(buildLocation())
        items.append(buildContact())
        items.append(buildDeviceInfo())
        items.append(buildScreenshots())
        items.append(buildCalendar())
        items.append(buildPasteboard())
        items.append(buildCamera())
        items.append(buildAudio())
        items.append(buildAlbum())
        items.append(buildLocalNetwork())
        items.append(buildRTC())
        return items
    }

    private func delayAction(_ name: String, delayTime: Int, view: UIView, invoke: @escaping ()throws -> Void) {
        Logger.debug("\(name) start in \(Date())")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(delayTime), execute: {
            Logger.debug("\(name) end in \(Date())")
            let toast = name
            do {
                try invoke()
                let config = UDToastConfig(toastType: .info, text: toast + " invoke success", operation: nil)
                UDToast.showToast(with: config, on: view)
            } catch {
                let config = UDToastConfig(toastType: .info, text: toast + " invoke fail", operation: nil)
                UDToast.showToast(with: config, on: view)
                Logger.error(error.localizedDescription)
            }
        })
    }
}

/// crash方法
extension SensitivityAPIData {
    private func buildCrash() -> SectionData {
        var datas = [APIData]()
        datas.append(crashMethod())
        datas.append(getCrashCount())
        let section = SectionData(type: "Crash", apiDatas: datas)
        return section
    }

    private func crashMethod() -> APIData {
        return APIData(title: "will crash") { delayTime, view in
            delayAction("will crash", delayTime: delayTime, view: view) {
                let optionlValue: String? = nil
                Logger.info("yyf: crash")
                _ = optionlValue!
            }
        }
    }

    private func getCrashCount() -> APIData {
        return APIData(title: "getCrashCount") { delayTime, view in
            let string = UIPasteboard.general.string ?? "value is nil"
            Logger.info("yyf: getCrashCount: \(String(describing: string))")
            let config = UDToastConfig(toastType: .info, text: string, operation: nil)
            UDToast.showToast(with: config, on: view)
        }
    }
}

/// 一些测试方法
extension SensitivityAPIData {
    private func monitorFuse() -> SectionData {
        var datas = [APIData]()
        datas.append(setString())
        datas.append(getString())
        datas.append(setStrings())
        datas.append(getStrings())
        datas.append(setURL())
        datas.append(getURL())
        datas.append(setURLs())
        datas.append(getURLs())
        datas.append(setImage())
        datas.append(getImage())
        datas.append(setImages())
        datas.append(getImages())
        datas.append(setColor())
        datas.append(getColor())
        datas.append(setColors())
        datas.append(getColors())
        datas.append(setItems())
        datas.append(getItems())
        datas.append(setItemsWithOption())
        datas.append(valuesForPasteboardType())
        datas.append(dataForPasteboardType())
        datas.append(idfvNew())
        datas.append(fetchCurrentWithCompletionHandler())
        datas.append(CNCopyCurrentNetworkInfoNew())
        let section = SectionData(type: "MonitorFuse", apiDatas: datas)
        return section
    }

    private func setString() -> APIData {
        return APIData(title: "setString") { delayTime, view in
            delayAction("setString", delayTime: delayTime, view: view) {
                UIPasteboard.general.string = "test"
                Logger.info("yyf: setString")
            }
        }
    }

    private func getString() -> APIData {
        return APIData(title: "getString") { delayTime, view in
            delayAction("getString", delayTime: delayTime, view: view) {
                let string = UIPasteboard.general.string
                Logger.info("yyf: getString: \(String(describing: string))")
            }
        }
    }

    private func setStrings() -> APIData {
        return APIData(title: "setStrings") { delayTime, view in
            delayAction("setStrings", delayTime: delayTime, view: view) {
                UIPasteboard.general.strings = ["test1", "test2"]
                Logger.info("yyf: setStrings")
            }
        }
    }

    private func getStrings() -> APIData {
        return APIData(title: "getStrings") { delayTime, view in
            delayAction("getStrings", delayTime: delayTime, view: view) {
                let strings = UIPasteboard.general.strings
                Logger.info("yyf: getStrings: \(String(describing: strings))")
            }
        }
    }

    private func setURL() -> APIData {
        return APIData(title: "setURL") { delayTime, view in
            delayAction("setURL", delayTime: delayTime, view: view) {
                UIPasteboard.general.url = URL(string: "https://www.example.com")
                Logger.info("yyf: setURL")
            }
        }
    }

    private func getURL() -> APIData {
        return APIData(title: "getURL") { delayTime, view in
            delayAction("getURL", delayTime: delayTime, view: view) {
                let url = UIPasteboard.general.url
                Logger.info("yyf: getURL: \(String(describing: url))")
            }
        }
    }

    private func setURLs() -> APIData {
        return APIData(title: "setURLs") { delayTime, view in
            delayAction("setURLs", delayTime: delayTime, view: view) {
                if let url = URL(string: "https://www.example.com") {
                    let tempURLs: [URL] = [url, url]
                    UIPasteboard.general.urls = tempURLs
                    Logger.info("yyf: setURLs")
                }
            }
        }
    }

    private func getURLs() -> APIData {
        return APIData(title: "getURLs") { delayTime, view in
            delayAction("getURLs", delayTime: delayTime, view: view) {
                let urls = UIPasteboard.general.urls
                Logger.info("yyf: getURLs: \(String(describing: urls))")
            }
        }
    }

    private func setImage() -> APIData {
        return APIData(title: "setImage") { delayTime, view in
            delayAction("setImage", delayTime: delayTime, view: view) {
                if #available(iOS 13.0, *) {
                    UIPasteboard.general.image = UIImage(systemName: "chevron.right")
                } else {
                    // Fallback on earlier versions
                }
                Logger.info("yyf: setImage")
            }
        }
    }

    private func getImage() -> APIData {
        return APIData(title: "getImage") { delayTime, view in
            delayAction("getImage", delayTime: delayTime, view: view) {
                let image = UIPasteboard.general.image
                Logger.info("yyf: getImage: \(String(describing: image))")
            }
        }
    }

    private func setImages() -> APIData {
        return APIData(title: "setImages") { delayTime, view in
            delayAction("setImages", delayTime: delayTime, view: view) {
                if #available(iOS 13.0, *), let image = UIImage(systemName: "chevron.right") {
                    UIPasteboard.general.images = [image, image]
                } else {
                    // Fallback on earlier versions
                }
                Logger.info("yyf: setImages")
            }
        }
    }

    private func getImages() -> APIData {
        return APIData(title: "getImages") { delayTime, view in
            delayAction("getImages", delayTime: delayTime, view: view) {
                let images = UIPasteboard.general.images
                Logger.info("yyf: getImages: \(String(describing: images))")
            }
        }
    }

    private func setColor() -> APIData {
        return APIData(title: "setColor") { delayTime, view in
            delayAction("setColor", delayTime: delayTime, view: view) {
                if #available(iOS 13.0, *) {
                    let CG = UIColor(cgColor: CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5))
                    UIPasteboard.general.color = CG
                } else {
                    // Fallback on earlier versions
                }
                Logger.info("yyf: setColor")
            }
        }
    }

    private func getColor() -> APIData {
        return APIData(title: "getColor") { delayTime, view in
            delayAction("getColor", delayTime: delayTime, view: view) {
                let color = UIPasteboard.general.color
                Logger.info("yyf: getColor: \(String(describing: color))")
            }
        }
    }

    private func setColors() -> APIData {
        return APIData(title: "setColors") { delayTime, view in
            delayAction("setColors", delayTime: delayTime, view: view) {
                if #available(iOS 13.0, *) {
                    let CGs = [UIColor(cgColor: CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)),
                               UIColor(cgColor: CGColor(red: 0.2, green: 0.1, blue: 0.3, alpha: 0.5))]
                    UIPasteboard.general.colors = CGs
                } else {
                    // Fallback on earlier versions
                }
                Logger.info("yyf: setColors")
            }
        }
    }

    private func getColors() -> APIData {
        return APIData(title: "getColors") { delayTime, view in
            delayAction("getColors", delayTime: delayTime, view: view) {
                let colors = UIPasteboard.general.colors
                Logger.info("yyf: getColors: \(String(describing: colors))")
            }
        }
    }

    private func setItems() -> APIData {
        return APIData(title: "setItems") { delayTime, view in
            delayAction("setItems", delayTime: delayTime, view: view) {
                UIPasteboard.general.items = [["testString": "testString"]]
                Logger.info("yyf: setItems")
            }
        }
    }

    private func getItems() -> APIData {
        return APIData(title: "getItems") { delayTime, view in
            delayAction("getItems", delayTime: delayTime, view: view) {
                if let item = UIPasteboard.general.items.first {
                    for (key, _) in item {
                        Logger.info("yyf: getItems: \(key)")
                        return
                    }
                }
                Logger.info("yyf: getItems: is nil")
            }
        }
    }

    private func setItemsWithOption() -> APIData {
        return APIData(title: "setItems:options") { delayTime, view in
            delayAction("setItems:options", delayTime: delayTime, view: view) {
                UIPasteboard.general.setItems([["testStringWithOption": "testStringWithOption"]], options: [.localOnly: true])
                Logger.info("yyf: setItems:options")
            }
        }
    }

    private func valuesForPasteboardType() -> APIData {
        return APIData(title: "valuesForPasteboardType") { delayTime, view in
            delayAction("valuesForPasteboardType", delayTime: delayTime, view: view) {
                let values = UIPasteboard.general.values(forPasteboardType: "string", inItemSet: .none)
                Logger.info("yyf: valuesForPasteboardType: \(String(describing: values))")
            }
        }
    }

    private func dataForPasteboardType() -> APIData {
        return APIData(title: "dataForPasteboardType") { delayTime, view in
            delayAction("dataForPasteboardType", delayTime: delayTime, view: view) {
                let data = UIPasteboard.general.data(forPasteboardType: "string", inItemSet: .none)
                Logger.info("yyf: dataForPasteboardType: \(String(describing: data))")
            }
        }
    }

    private func idfvNew() -> APIData {
        return APIData(title: "idfv") { delayTime, view in
            delayAction("idfv", delayTime: delayTime, view: view) {
                let idfv = UIDevice.current.identifierForVendor
                Logger.info("yyf: idfv: \(String(describing: idfv))")
                UDToast.showSuccess(with: idfv?.uuidString ?? "", on: view)
            }
        }
    }

    private func fetchCurrentWithCompletionHandler() -> APIData {
        return APIData(title: "NEHotspotNetwork.fetchCurrent") { delayTime, view in
            delayAction("NEHotspotNetwork.fetchCurrent", delayTime: delayTime, view: view) {
                if #available(iOS 14.0, *) {
                    NEHotspotNetwork.fetchCurrent { network in
                        if let network = network {
                            Logger.info("yyf: ssid: \(String(describing: network.ssid))")
                            Logger.info("yyf: bssid: \(String(describing: network.bssid))")
                        } else {
                            Logger.info("yyf: network is nil")
                        }
                    }
                } else {
                    // Fallback on earlier versions
                    Logger.info("yyf: Fallback on earlier versions")
                }
            }
        }
    }

    private func CNCopyCurrentNetworkInfoNew() -> APIData {
        return APIData(title: "CNCopyCurrentNetworkInfo") { delayTime, view in
            delayAction("CNCopyCurrentNetworkInfo", delayTime: delayTime, view: view) {
                if let interfaces = CNCopySupportedInterfaces() as NSArray? {
                    for interface in interfaces {
                        if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                            let ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
                            Logger.info("yyf: CNCopyCurrentNetworkInfo ssid: \(String(describing: ssid))")
                            let bssid = interfaceInfo[kCNNetworkInfoKeyBSSID as String] as? String
                            Logger.info("yyf: CNCopyCurrentNetworkInfo bssid: \(String(describing: bssid))")
                        } else {
                            Logger.info("yyf: CNCopyCurrentNetworkInfo interface network is nil")
                        }
                    }
                } else {
                    Logger.info("yyf: CNCopyCurrentNetworkInfo network is nil")
                }
            }
        }
    }

}

/// location
extension SensitivityAPIData {
    private func buildLocation() -> SectionData {
        var datas = [APIData]()
        datas.append(requestLocation())
        datas.append(startUpdatingLocation())
        datas.append(requestWhenInUseAuthorization())
        #if !os(visionOS)
        datas.append(requestAlwaysAuthorization())
        datas.append(allowsBackgroundLocationUpdates())
        datas.append(startUpdatingHeading())
        datas.append(startMonitoring())
        datas.append(startMonitoringSignificantLocationChanges())
        datas.append(startRangingBeacons())
        if #available(iOS 13, *) {
            datas.append(startRangingBeaconsSatisfyingConstraint())
        }
        #endif
        let section = SectionData(type: "location", apiDatas: datas)
        return section
    }

    private func requestLocation() -> APIData {
        return APIData(title: "[CLLocationManager requestLocation]") { delayTime, view in
            delayAction("LocationEntry.requestLocation", delayTime: delayTime, view: view) {
                let locationManager = CLLocationManager()
                locationManager.delegate = LocationManagerDelegate.instance
                try LocationEntry.requestLocation(forToken: token, manager: locationManager)
            }
        }
    }

    private func startUpdatingLocation() -> APIData {
        return APIData(title: "[CLLocationManager startUpdatingLocation]") { delayTime, view in
            delayAction("LocationEntry.startUpdatingLocation", delayTime: delayTime, view: view) {
                let locationManager = CLLocationManager()
                locationManager.delegate = LocationManagerDelegate.instance
                try LocationEntry.startUpdatingLocation(forToken: token, manager: locationManager)
            }
        }
    }

    private func requestWhenInUseAuthorization() -> APIData {
        return APIData(title: "[CLLocationManager  requestWhenInUseAuthorization]") { delayTime, view in
            delayAction("LocationEntry.requestWhenInUseAuthorization", delayTime: delayTime, view: view) {
                let locationManager = CLLocationManager()
                locationManager.delegate = LocationManagerDelegate.instance
                try LocationEntry.requestWhenInUseAuthorization(forToken: token, manager: locationManager)
            }
        }
    }

    #if !os(visionOS)
    private func requestAlwaysAuthorization() -> APIData {
        return APIData(title: "[CLLocationManager requestAlwaysAuthorization]") { delayTime, view in
            delayAction("CLLocationManager.requestAlwaysAuthorization", delayTime: delayTime, view: view) {
                try LocationEntry.requestAlwaysAuthorization(forToken: token, manager: CLLocationManager())
            }
        }
    }

    private func allowsBackgroundLocationUpdates() -> APIData {
        return APIData(title: "[CLLocationManager allowsBackgroundLocationUpdates]") { delayTime, view in
            delayAction("CLLocationManager.allowsBackgroundLocationUpdates", delayTime: delayTime, view: view) {
                _ = try LocationEntry.allowsBackgroundLocationUpdates(forToken: token, manager: CLLocationManager())
            }
        }
    }

    private func startUpdatingHeading() -> APIData {
        return APIData(title: "[CLLocationManager startUpdatingHeading]") { delayTime, view in
            delayAction("CLLocationManager.startUpdatingHeading", delayTime: delayTime, view: view) {
                try LocationEntry.startUpdatingHeading(forToken: token, manager: CLLocationManager())
            }
        }
    }

    private func startMonitoringSignificantLocationChanges() -> APIData {
        return APIData(title: "[CLLocationManager startMonitoringSignificantLocationChanges]") { delayTime, view in
            delayAction("CLLocationManager.startMonitoringSignificantLocationChanges", delayTime: delayTime, view: view) {
                try LocationEntry.startMonitoringSignificantLocationChanges(forToken: token, manager: CLLocationManager())
            }
        }
    }

    private func startMonitoring() -> APIData {
        return APIData(title: "[CLLocationManager startMonitoringForRegion:]") { delayTime, view in
            delayAction("CLLocationManager.startMonitoring", delayTime: delayTime, view: view) {
                let locationManager = LocationManager()
                locationManager.startMonitoringForRegion()
            }
        }
    }

    private func startRangingBeacons() -> APIData {
        return APIData(title: "[CLLocationManager startRangingBeaconsInRegion:]") { delayTime, view in
            delayAction("CLLocationManager.startRangingBeacons", delayTime: delayTime, view: view) {
                try LocationEntry.startRangingBeacons(forToken: token, manager: CLLocationManager(), region: CLBeaconRegion())
            }
        }
    }

    @available(iOS 13.0, *)
    private func startRangingBeaconsSatisfyingConstraint() -> APIData {
        return APIData(title: "[CLLocationManager startRangingBeaconsSatisfyingConstraint:]") { delayTime, view in
            delayAction("CLLocationManager.startRangingBeacons", delayTime: delayTime, view: view) {
                let uuid = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
                let constraint = CLBeaconIdentityConstraint(uuid: uuid, major: 1, minor: 1)
                try LocationEntry.startRangingBeaconsSatisfyingConstraint(forToken: token,
                                                                          manager: CLLocationManager(),
                                                                          constraint: constraint)
            }
        }
    }
    #endif
}

/// contacts
extension SensitivityAPIData {
    private func buildContact() -> SectionData {
        var datas = [APIData]()
        datas.append(requestAccessForEntityType())
        datas.append(enumerateContactsWithFetchRequest())
        datas.append(execute())
        let section = SectionData(type: "contacts", apiDatas: datas)
        return section
    }

    private func requestAccessForEntityType() -> APIData {
        return APIData(title: "[CNContactStore requestAccessForEntityType:completionHandler:]") { delayTime, view in
            delayAction("CNContactStore.requestAccessForEntityType", delayTime: delayTime, view: view) {
                try ContactsEntry.requestAccess(forToken: token, contactsStore: CNContactStore(), forEntityType: .contacts,
                                                completionHandler: { _, _ in })
            }
        }
    }

    private func enumerateContactsWithFetchRequest() -> APIData {
        return APIData(title: "[CNContactStore enumerateContactsWithFetchRequest:usingBlock:]") { delayTime, view in
            delayAction("CNContactStore.enumerateContactsWithFetchRequest", delayTime: delayTime, view: view) {
                try ContactsEntry.enumerateContacts(forToken: token, contactsStore: CNContactStore(),
                                                    withFetchRequest: CNContactFetchRequest(keysToFetch: [CNKeyDescriptor]()),
                                                    usingBlock: { _, _ in })
            }
        }
    }

    private func execute() -> APIData {
        return APIData(title: "[CNContactStore executeSaveRequest:error:]") { delayTime, view in
            delayAction("CNContactStore.execute", delayTime: delayTime, view: view) {
                try ContactsEntry.execute(forToken: token, store: CNContactStore(), saveRequest: CNSaveRequest())
            }
        }
    }
}

/// deviceInfo
extension SensitivityAPIData {
    private func buildDeviceInfo() -> SectionData {
        var datas = [APIData]()
        datas.append(fetchCurrent())
        datas.append(idfv())
        if #available(iOS 12.0, *) {
            datas.append(createRPSystemBroadcastPickerView())
        }
        datas.append(userNotificationCenter())
        datas.append(cnCopyCurrentNetworkInfo())
        datas.append(getifaddrs())
        datas.append(startAccelerometerUpdates())
        datas.append(startDeviceMotionUpdates())
        #if !os(visionOS)
        if #available(iOS 10, *) {
        } else {
            datas.append(currentCalls())
        }
        #endif
        datas.append(evaluatePolicy())
        datas.append(mobileCountryCode())
        datas.append(mobileNetworkCode())
        datas.append(reverseGeocodeLocation())
        datas.append(isProximityMonitoringEnabled())
        datas.append(proximityState())
        datas.append(setProximityMonitoringEnabled())
        if #available(iOS 14, *) {
            datas.append(ssid())
            datas.append(bssid())
        }
        #if !os(visionOS)
        datas.append(queryPedometerData())
        #endif
        if #available(iOS 12, *) {
            datas.append(createRPSystemBroadcastPickerViewWithFrame())
        }
        datas.append(scanForPeripherals())
        datas.append(getDeviceName())
        let section = SectionData(type: "deviceInfo", apiDatas: datas)
        return section
    }

    private func fetchCurrent() -> APIData {
        return APIData(title: "[NEHotspotNetwork fetchCurrentWithCompletionHandler:]") { delayTime, view in
            delayAction("DeviceInfoEntry.fetchCurrent", delayTime: delayTime, view: view) {
                if #available(iOS 14.0, *) {
                    try DeviceInfoEntry.fetchCurrent(forToken: token) { _ in }
                }
            }
        }
    }
    
    private func idfv() -> APIData {
        return APIData(title: "IDFV") { delayTime, view in
            delayAction("UIDevice.identifierForVendor", delayTime: delayTime, view: view) {
                let idfv = UIDevice.current.identifierForVendor
                UDToast.showSuccess(with: idfv?.uuidString ?? "", on: view)
            }
        }
    }
    
    @available(iOS 12.0, *)
    private func createRPSystemBroadcastPickerView() -> APIData {
        return APIData(title: "RPSystemBroadcastPickerView") { delayTime, view in
            delayAction("RPSystemBroadcastPickerView.init()", delayTime: delayTime, view: view) {
                _ = RPSystemBroadcastPickerView.init()
            }
        }
    }
    
    private func userNotificationCenter() -> APIData {
        return APIData(title: "UNUserNotificationCenter") { delayTime, view in
            delayAction("UNUserNotificationCenter_requestAuthorizationWithOptions_completionHandler_", delayTime: delayTime, view: view) {
                UNUserNotificationCenter.current().requestAuthorization { _, _ in
                    print("UNUserNotificationCenter requestAuthorizationWithOptions.")
                }
            }
        }
    }

    private func cnCopyCurrentNetworkInfo() -> APIData {
        return APIData(title: "CNCopyCurrentNetworkInfo") { delayTime, view in
            delayAction("DeviceInfoEntry.CNCopyCurrentNetworkInfo", delayTime: delayTime, view: view) {
                _ = try DeviceInfoEntry.CNCopyCurrentNetworkInfo(forToken: token, "" as CFString)
            }
        }
    }

    private func getifaddrs() -> APIData {
        return APIData(title: "getifaddrs") { delayTime, view in
            delayAction("DeviceInfoEntry.getifaddrs", delayTime: delayTime, view: view) {
                var ifAddrsPtr: UnsafeMutablePointer<ifaddrs>?
                _ = try DeviceInfoEntry.getifaddrs(forToken: token, &ifAddrsPtr)
            }
        }
    }

    private func startAccelerometerUpdates() -> APIData {
        return APIData(title: "[CMMotionManager startAccelerometerUpdatesToQueue:withHandler:]") { delayTime, view in
            delayAction("DeviceInfoEntry.startAccelerometerUpdates", delayTime: delayTime, view: view) {
                try DeviceInfoEntry.startAccelerometerUpdates(forToken: token, manager: CMMotionManager(), to: .main) { _, _  in }
            }
        }
    }

    private func startDeviceMotionUpdates() -> APIData {
        return APIData(title: "[CMMotionManager startDeviceMotionUpdatesToQueue: withHandler:]") { delayTime, view in
            delayAction("DeviceInfoEntry.startDeviceMotionUpdates", delayTime: delayTime, view: view) {
                try DeviceInfoEntry.startDeviceMotionUpdates(forToken: token, manager: CMMotionManager(), to: .main) { _, _ in }
            }
        }
    }

    #if !os(visionOS)
    @available(iOS, introduced: 4.0, deprecated: 10)
    private func currentCalls() -> APIData {
        return APIData(title: "[CTCallCenter currentCalls]") { delayTime, view in
            delayAction("DeviceInfoEntry.currentCalls", delayTime: delayTime, view: view) {
                _ = try DeviceInfoEntry.currentCalls(forToken: token, callCenter: CTCallCenter())
            }
        }
    }
    #endif

    private func evaluatePolicy() -> APIData {
        return APIData(title: "[LAContext evaluatePolicy:localizedReason:reply:]") { delayTime, view in
            delayAction("DeviceInfoEntry.evaluatePolicy", delayTime: delayTime, view: view) {
                try DeviceInfoEntry.evaluatePolicy(forToken: token, laContext: LAContext(), policy: .deviceOwnerAuthenticationWithBiometrics, localizedReason: "指纹解锁", reply: { _, _ in })
            }
        }
    }

    private func mobileCountryCode() -> APIData {
        return APIData(title: "[CTCarrier mobileCountryCode]") { delayTime, view in
            delayAction("CTCarrier.mobileCountryCode", delayTime: delayTime, view: view) {
                _ = CTCarrier().mobileCountryCode
            }
        }
    }

    private func mobileNetworkCode() -> APIData {
        return APIData(title: "[CTCarrier mobileNetworkCode]") { delayTime, view in
            delayAction("CTCarrier.mobileNetworkCode", delayTime: delayTime, view: view) {
                _ = CTCarrier().mobileNetworkCode
            }
        }
    }

    private func reverseGeocodeLocation() -> APIData {
        return APIData(title: "[CLGeocoder reverseGeocodeLocation:completionHandler:]") { delayTime, view in
            delayAction("DeviceInfoEntry.reverseGeocodeLocation", delayTime: delayTime, view: view) {
                try DeviceInfoEntry.reverseGeocodeLocation(forToken: token, geocoder: CLGeocoder(), userLocation: CLLocation(), completionHandler: { _, _ in })
            }
        }
    }

    private func isProximityMonitoringEnabled() -> APIData {
        return APIData(title: "[UIDevice isProximityMonitoringEnabled]") { delayTime, view in
            delayAction("DeviceInfoEntry.isProximityMonitoringEnabled", delayTime: delayTime, view: view) {
                _ = try DeviceInfoEntry.isProximityMonitoringEnabled(forToken: token, device: UIDevice.current)
            }
        }
    }

    private func proximityState() -> APIData {
        return APIData(title: "[UIDevice proximityState]") { delayTime, view in
            delayAction("DeviceInfoEntry.proximityState", delayTime: delayTime, view: view) {
                _ = try DeviceInfoEntry.proximityState(forToken: token, device: UIDevice.current)
            }
        }
    }

    private func setProximityMonitoringEnabled() -> APIData {
        return APIData(title: "[UIDevice setProximityMonitoringEnabled:]") { delayTime, view in
            delayAction("UIDevice.setIsProximityMonitoringEnabled", delayTime: delayTime, view: view) {
                _ = try DeviceInfoEntry.setProximityMonitoringEnabled(forToken: token, device: UIDevice(), isEnabled: true)
            }
        }
    }

    private func startAdvertising() -> APIData {
        return APIData(title: "[CBPeripheralManager startAdvertising:]") { delayTime, view in
            delayAction("CBPeripheralManager.startAdvertising", delayTime: delayTime, view: view) {
                try DeviceInfoEntry.startAdvertising(forToken: token, manager: CBPeripheralManager(), advertisementData: nil)
            }
        }
    }

    @available(iOS, introduced: 14.0)
    private func ssid() -> APIData {
        return APIData(title: "[NEHotspotNetwork SSID]") { delayTime, view in
            delayAction("NEHotspotNetwork.ssid", delayTime: delayTime, view: view) {
                NEHotspotNetwork.fetchCurrent(completionHandler: { network in
                    if let network = network {
                        _ = try? DeviceInfoEntry.ssid(forToken: token, net: network)
                    }
                })
            }
        }
    }

    @available(iOS, introduced: 14.0)
    private func bssid() -> APIData {
        return APIData(title: "[NEHotspotNetwork BSSID]") { delayTime, view in
            delayAction("NEHotspotNetwork.bssid", delayTime: delayTime, view: view) {
                NEHotspotNetwork.fetchCurrent(completionHandler: { network in
                    if let network = network {
                        _ = try? DeviceInfoEntry.bssid(forToken: token, net: network)
                    }
                })
            }
        }
    }

    #if !os(visionOS)
    private func queryPedometerData() -> APIData {
        return APIData(title: "[CMPedometer queryPedometerDataFromDate:toDate:withHandler:]") { delayTime, view in
            delayAction("CMPedometer.queryPedometerData", delayTime: delayTime, view: view) {
                let date = Date()
                try DeviceInfoEntry.queryPedometerData(forToken: token,
                                                       pedometer: CMPedometer(),
                                                       from: date,
                                                       to: date,
                                                       withHandler: { _, _ in })
            }
        }
    }
    #endif

    @available(iOS, introduced: 12.0)
    private func createRPSystemBroadcastPickerViewWithFrame() -> APIData {
        return APIData(title: "[RPSystemBroadcastPickerView initWithFrame]") { delayTime, view in
            delayAction("RPSystemBroadcastPickerView.init", delayTime: delayTime, view: view) {
                _ = try DeviceInfoEntry.createRPSystemBroadcastPickerViewWithFrame(forToken: token, frame: CGRect())
            }
        }
    }

    private func scanForPeripherals() -> APIData {
        return APIData(title: "[CBCentralManager scanForPeripheralsWithServices:options:]") { delayTime, view in
            delayAction("CBCentralManager.scanForPeripherals", delayTime: delayTime, view: view) {
                try DeviceInfoEntry.scanForPeripherals(forToken: token, manager: CBCentralManager(), withServices: nil)
            }
        }
    }

    private func getDeviceName() -> APIData {
        return APIData(title: "[UIDevice name]") { delayTime, view in
            delayAction("UIDevice.name", delayTime: delayTime, view: view) {
                _ = try DeviceInfoEntry.getDeviceName(forToken: token, device: UIDevice())
            }
        }
    }
}

/// Screenshots
extension SensitivityAPIData {
    private func buildScreenshots() -> SectionData {
        var datas = [APIData]()
        datas.append(resizableSnapshotViewFromRect())
        datas.append(drawHierarchy())
        let section = SectionData(type: "Screenshots", apiDatas: datas)
        return section
    }
    
    private func resizableSnapshotViewFromRect() -> APIData {
        return APIData(title: "[UIView resizableSnapshotViewFromRect:afterScreenUpdates:withCapInsets:]") { delayTime, view in
            delayAction("UIView.resizableSnapshotViewFromRect", delayTime: delayTime, view: view) {
                _ = view.resizableSnapshotView(from: view.bounds, afterScreenUpdates: false, withCapInsets: UIEdgeInsets.zero)
            }
        }
    }
    
    private func drawHierarchy() -> APIData {
        return APIData(title: "[UIView drawViewHierarchyInRect:afterScreenUpdates:]") { delayTime, view in
            delayAction("UIView.drawViewHierarchyInRect", delayTime: delayTime, view: view) {
                _ = try DeviceInfoEntry.drawHierarchy(forToken: token, view: view, rect: view.bounds, afterScreenUpdates: true)
            }
        }
    }
}

/// Calendar
extension SensitivityAPIData {
    private func buildCalendar() -> SectionData {
        var datas = [APIData]()
        datas.append(eventWithEventStore())
        datas.append(requestAccessToEntityType())
        datas.append(event())
        datas.append(calendars())
        datas.append(calendar())
        datas.append(calendarItem())
        datas.append(calendarsWithSource())
        if #available(iOS 17.0, *) {
            datas.append(requestWriteOnlyAccessToEvents())
            datas.append(requestFullAccessToEvents())
            datas.append(requestFullAccessToReminders())
        }
        let section = SectionData(type: "Calendar", apiDatas: datas)
        return section
    }

    // 构造函数，线上没使用
    private func eventWithEventStore() -> APIData {
        return APIData(title: "[EKEvent eventWithEventStore:]") { delayTime, view in
            delayAction("EKEvent.eventWithEventStore", delayTime: delayTime, view: view) {
                _ = EKEvent(eventStore: EKEventStore())
            }
        }
    }

    private func requestAccessToEntityType() -> APIData {
        return APIData(title: "[EKEventStore requestAccessToEntityType:completion:]") { delayTime, view in
            delayAction("EKEventStore.requestAccessToEntityType", delayTime: delayTime, view: view) {
                _ = try CalendarEntry.requestAccess(forToken: token,
                                                    eventStore: EKEventStore(),
                                                    toEntityType: EKEntityType.event,
                                                    completion: { _,_ in })
            }
        }
    }

    private func calendars() -> APIData {
        return APIData(title: "[EKEventStore calendarsForEntityType:]") { delayTime, view in
            delayAction("EKEventStore.calendars", delayTime: delayTime, view: view) {
                _ = try CalendarEntry.calendars(forToken: token, eventStore: EKEventStore(), forEntityType: .event)
            }
        }
    }

    private func calendar() -> APIData {
        return APIData(title: "[EKEventStore calendarWithIdentifier:]") { delayTime, view in
            delayAction("EKEventStore.calendar", delayTime: delayTime, view: view) {
                _ = try CalendarEntry.calendar(forToken: token, eventStore: EKEventStore(), withIdentifier: "")
            }
        }
    }

    private func calendarItem() -> APIData {
        return APIData(title: "[EKEventStore calendarItemWithIdentifier:]") { delayTime, view in
            delayAction("EKEventStore.calendarItem", delayTime: delayTime, view: view) {
                _ = try CalendarEntry.calendarItem(forToken: token, eventStore: EKEventStore(), withIdentifier: "")
            }
        }
    }

    private func calendarsWithSource() -> APIData {
        return APIData(title: "[EKSource calendarsForEntityType:] ") { delayTime, view in
            delayAction("EKSource.calendars", delayTime: delayTime, view: view) {
                _ = try CalendarEntry.calendars(forToken: token,
                                                source: EKSource(),
                                                entityType: .event)
            }
        }
    }

    private func event() -> APIData {
        return APIData(title: "[EKEventStore eventWithIdentifier:]") { delayTime, view in
            delayAction("EKEventStore.event", delayTime: delayTime, view: view) {
                _ = try CalendarEntry.event(forToken: token, eventStore: EKEventStore(), identifier: "")
            }
        }
    }

    @available(iOS 17.0, *)
    private func requestWriteOnlyAccessToEvents() -> APIData {
        return APIData(title: "[EKEventStore requestWriteOnlyAccessToEventsWithCompletion:]") { delayTime, view in
            delayAction("EKEventStore.requestWriteOnlyAccessToEvents", delayTime: delayTime, view: view) {
                try CalendarEntry.requestWriteOnlyAccessToEvents(forToken: token,
                                                                 eventStore: EKEventStore(),
                                                                 completion: { _, _ in })
            }
        }
    }

    @available(iOS 17.0, *)
    private func requestFullAccessToEvents() -> APIData {
        return APIData(title: "[EKEventStore requestFullAccessToEventsWithCompletion:]") { delayTime, view in
            delayAction("EKEventStore.requestFullAccessToEvents", delayTime: delayTime, view: view) {
                try CalendarEntry.requestFullAccessToEvents(forToken: token, eventStore: EKEventStore(), completion: { _, _ in })
            }
        }
    }

    @available(iOS 17.0, *)
    private func requestFullAccessToReminders() -> APIData {
        return APIData(title: "[EKEventStore requestFullAccessToRemindersWithCompletion:]") { delayTime, view in
            delayAction("EKEventStore.requestFullAccessToReminders", delayTime: delayTime, view: view) {
                try CalendarEntry.requestFullAccessToReminders(forToken: token,
                                                               eventStore: EKEventStore(),
                                                               completion: { _, _ in })
            }
        }
    }
}

/// Pasteboard
extension SensitivityAPIData {
    private func buildPasteboard() -> SectionData {
        var datas = [APIData]()
        datas.append(image())
        datas.append(items())
        let section = SectionData(type: "Pasteboard", apiDatas: datas)
        return section
    }

    private func image() -> APIData {
        return APIData(title: "[UIPasteboard image]") { delayTime, view in
            delayAction("UIPasteboard.image", delayTime: delayTime, view: view) {
                _ = UIPasteboard.general.image
            }
        }
    }

    private func items() -> APIData {
        return APIData(title: "[UIPasteboard items]") { delayTime, view in
            delayAction("UIPasteboard.items", delayTime: delayTime, view: view) {
                _ = SCPasteboard.general(SCPasteboard.defaultConfig()).items?.count ?? 0
            }
        }
    }
}

/// Video
extension SensitivityAPIData {
    private func buildCamera() -> SectionData {
        var datas = [APIData]()
        datas.append(requestAccessForMediaTypeAVMediaTypeVideo())
        #if !os(visionOS)
        datas.append(startRunning())
        datas.append(stopRunning())
        datas.append(defaultDeviceWithMediaTypeVideo())
        if #available(iOS 10, *) {
        } else {
            datas.append(captureStillImageAsynchronously())
        }
        datas.append(defaultCameraDeviceWithDeviceType())
        #endif
        let section = SectionData(type: "Video", apiDatas: datas)
        return section
    }

    private func requestAccessForMediaTypeAVMediaTypeVideo() -> APIData {
        return APIData(title: "[AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:]") { delayTime, view in
            delayAction("AVCaptureDevice.requestAccessForMediaType:AVMediaTypeVideo", delayTime: delayTime, view: view) {
                try CameraEntry.requestAccessCamera(forToken: token, completionHandler: { _ in })
            }
        }
    }

    #if !os(visionOS)
    private func startRunning() -> APIData {
        return APIData(title: "[AVCaptureSession startRunning]") { delayTime, view in
            delayAction("AVCaptureSession.startRunning", delayTime: delayTime, view: view) {
                try CameraEntry.startRunning(forToken: token, session: AVCaptureSession())
            }
        }
    }
    
    private func stopRunning() -> APIData {
        return APIData(title: "[AVCaptureSession stopRunning]") { delayTime, view in
            delayAction("AVCaptureSession.stopRunning", delayTime: delayTime, view: view) {
                DispatchQueue.global().async {
                    AVCaptureSession().stopRunning()
                }
            }
        }
    }

    private func defaultDeviceWithMediaTypeVideo() -> APIData {
        return APIData(title: "[AVCaptureDevice defaultDeviceWithMediaType:Video]") { delayTime, view in
            delayAction("AVCaptureDevice.defaultDeviceWithMediaType(video)", delayTime: delayTime, view: view) {
                _ = try CameraEntry.defaultCameraDevice(forToken: token)
            }
        }
    }

    @available(iOS, introduced: 4.0, deprecated: 10)
    private func captureStillImageAsynchronously() -> APIData {
        return APIData(title: "[AVCaptureStillImageOutput captureStillImageAsynchronouslyFromConnection:completionHandler:]")
        { delayTime, view in
            delayAction("AVCaptureStillImageOutput.captureStillImageAsynchronouslyFromConnection", delayTime: delayTime, view: view) {
                if let connection = AVCaptureStillImageOutput().connection(with: .video) {
                    try CameraEntry.captureStillImageAsynchronously(forToken: token,
                                                                    photoFileOutput: AVCaptureStillImageOutput(),
                                                                    fromConnection: connection,
                                                                    completionHandler: { _,_ in })
                }
            }
        }
    }

    private func defaultCameraDeviceWithDeviceType() -> APIData {
        return APIData(title: "[AVCaptureDevice defaultDeviceWithDeviceType:mediaType:AVMediaTypeVideo position:]") { delayTime, view in
            delayAction("AVCaptureDevice.default", delayTime: delayTime, view: view) {
                _ = try CameraEntry.defaultCameraDeviceWithDeviceType(forToken: token,
                                                                      deviceType: .builtInDualCamera,
                                                                      position: .back)
            }
        }
    }
    #endif
}

/// Audio
extension SensitivityAPIData {
    private func buildAudio() -> SectionData {
        var datas = [APIData]()
        datas.append(audioOutputUnitStart())
        datas.append(requestRecordPermission())
        datas.append(requestAccessForMediaTypeAVMediaTypeAudio())
        datas.append(AUGraphStart())
        #if !os(visionOS)
        datas.append(defaultAudioDevice())
        datas.append(defaultAudioDeviceWithDeviceType())
        #endif
        let section = SectionData(type: "Audio", apiDatas: datas)
        return section
    }

    private func audioOutputUnitStart() -> APIData {
        return APIData(title: "AudioOutputUnitStart") { delayTime, view in
            delayAction("AudioOutputUnitStart", delayTime: delayTime, view: view) {
                var unit: AudioComponentInstance? = nil
                var inputDesc = AudioComponentDescription()
                inputDesc.componentType = kAudioUnitType_Output
                inputDesc.componentSubType = kAudioUnitSubType_RemoteIO
                inputDesc.componentManufacturer = kAudioUnitManufacturer_Apple
                inputDesc.componentFlags = 0
                inputDesc.componentFlagsMask = 0
                guard let inputComponent = AudioComponentFindNext(nil, &inputDesc) else {
                    return
                }
                AudioComponentInstanceNew(inputComponent, &unit)
                if let unit = unit {
                    var flag = 1;  //falg为1表示开启录制功能，为0则不开启
                    AudioUnitSetProperty(unit,
                                         kAudioOutputUnitProperty_EnableIO,
                                         kAudioUnitScope_Input,
                                         1,
                                         &flag,
                                         UInt32(MemoryLayout.size(ofValue: flag)));
                    _ = try AudioRecordEntry.audioOutputUnitStart(forToken: token, ci: unit)
                }
            }
        }
    }

    private func requestRecordPermission() -> APIData {
        return APIData(title: "[AVAudioSession requestRecordPermission]") { delayTime, view in
            delayAction("AVAudioSession.requestRecordPermission", delayTime: delayTime, view: view) {
                try AudioRecordEntry.requestRecordPermission(forToken: token, session: AVAudioSession.sharedInstance(),
                                                         response: { _ in })
            }
        }
    }

    private func requestAccessForMediaTypeAVMediaTypeAudio() -> APIData {
        return APIData(title: "[AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:]") { delayTime, view in
            delayAction("AVCaptureDevice.requestAccessForMediaType:AVMediaTypeAudio", delayTime: delayTime, view: view) {
                try AudioRecordEntry.requestAccessAudio(forToken: token, completionHandler: { _ in })
            }
        }
    }

    private func AUGraphStart() -> APIData {
        return APIData(title: "AUGraphStart") { delayTime, view in
            delayAction("AUGraphStart", delayTime: delayTime, view: view) {
                if let opa = OpaquePointer(bitPattern: 0) {
                    _ = try AudioRecordEntry.AUGraphStart(forToken: token, inGraph: opa)
                }
            }
        }
    }

    #if !os(visionOS)
    private func defaultAudioDevice() -> APIData {
        return APIData(title: "[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio]") { delayTime, view in
            delayAction("AVCaptureDevice.default", delayTime: delayTime, view: view) {
                _ = try AudioRecordEntry.defaultAudioDevice(forToken: token)
            }
        }
    }

    private func defaultAudioDeviceWithDeviceType() -> APIData {
        return APIData(title: "[AVCaptureDevice defaultDeviceWithDeviceType:mediaType:AVMediaTypeAudio position:]") { delayTime, view in
            delayAction("AVCaptureDevice.default", delayTime: delayTime, view: view) {
                _ = try AudioRecordEntry.defaultAudioDeviceWithDeviceType(forToken: token,
                                                                          deviceType: .builtInDualCamera,
                                                                          position: .back)
            }
        }
    }
    #endif
}

/// Album
extension SensitivityAPIData {
    private func buildAlbum() -> SectionData {
        var datas = [APIData]()
        datas.append(fetchAssets())
        datas.append(fetchTopLevelUserCollections())
        datas.append(requestAuthorization())
        if #available(iOS 14, *) {
            datas.append(requestAuthorizationForAccessLevel())
        }
        datas.append(fetchAssetCollectionsWithType())
        datas.append(requestData())
        datas.append(requestAVAssetForVideo())
        datas.append(requestExportSession())
        datas.append(requestImage())
        datas.append(requestPlayerItem())
        if #available(iOS 14, *) {
            datas.append(createPickerViewControllerWithConfiguration())
        }
        datas.append(createImagePickerController())
        datas.append(UIImageWriteToSavedPhotosAlbum())
        datas.append(UISaveVideoAtPathToSavedPhotosAlbum())
        datas.append(requestImageData())
        if #available(iOS 13, *) {
            datas.append(requestImageDataAndOrientation())
        }
        let section = SectionData(type: "Album", apiDatas: datas)
        return section
    }

    private func fetchAssets() -> APIData {
        return APIData(title: "[PHAsset fetchAssetsWithMediaType:options:]") { delayTime, view in
            delayAction("PHAsset.fetchAssets", delayTime: delayTime, view: view) {
                _ = try AlbumEntry.fetchAssets(forToken: token, withMediaType: .audio, options: nil)
            }
        }
    }

    private func fetchTopLevelUserCollections() -> APIData {
        return APIData(title: "[PHCollectionList fetchTopLevelUserCollectionsWithOptions:]") { delayTime, view in
            delayAction("PHCollectionList.fetchTopLevelUserCollections", delayTime: delayTime, view: view) {
                _ = try AlbumEntry.fetchTopLevelUserCollections(forToken: token, withOptions: nil)
            }
        }
    }

    private func requestAuthorization() -> APIData {
        return APIData(title: "[PHPhotoLibrary requestAuthorization:]") { delayTime, view in
            delayAction("PHPhotoLibrary.requestAuthorization", delayTime: delayTime, view: view) {
                try AlbumEntry.requestAuthorization(forToken: token, handler: { _ in })
            }
        }
    }

    @available(iOS, introduced: 14.0)
    private func requestAuthorizationForAccessLevel() -> APIData {
        return APIData(title: "[PHPhotoLibrary requestAuthorizationForAccessLevel:handler:]") { delayTime, view in
            delayAction("PHPhotoLibrary.requestAuthorizationForAccessLevel", delayTime: delayTime, view: view) {
                try AlbumEntry.requestAuthorization(forToken: token, forAccessLevel: .addOnly, handler: { _ in })
            }
        }
    }

    private func fetchAssetCollectionsWithType() -> APIData {
        return APIData(title: "[PHAssetCollection fetchAssetCollectionsWithType:subtype:options:]") { delayTime, view in
            delayAction("PHAssetCollection.fetchAssetCollectionsWithType", delayTime: delayTime, view: view) {
                _ = try AlbumEntry.fetchAssetCollections(forToken: token, withType: PHAssetCollectionType.smartAlbum,
                                                     subtype: PHAssetCollectionSubtype.albumRegular, options: nil)
            }
        }
    }

    private func requestData() -> APIData {
        return APIData(title: "[PHAssetResourceManager requestDataForAssetResource:options:dataReceivedHandler:completionHandler:]")
        { delayTime, view in
            delayAction("PHAssetResourceManager.requestData", delayTime: delayTime, view: view) {
                _ = try AlbumEntry.requestData(forToken: token,
                                               manager: PHAssetResourceManager(),
                                               forResource: PHAssetResource(),
                                               options: nil,
                                               dataReceivedHandler: { _ in },
                                               completionHandler: { _ in })
            }
        }
    }

    private func requestAVAssetForVideo() -> APIData {
        return APIData(title: "[PHImageManager requestAVAssetForVideo:options:resultHandler:]") { delayTime, view in
            delayAction("PHImageManager.requestAVAssetForVideo", delayTime: delayTime, view: view) {
                _ = try AlbumEntry.requestAVAsset(forToken: token, manager: PHImageManager.default(), forVideoAsset: PHAsset(),
                                              options: nil, resultHandler: { _,_,_ in })
            }
        }
    }

    private func requestExportSession() -> APIData {
        return APIData(title: "[PHImageManager requestExportSessionForVideo:options:exportPreset:resultHandler:]") { delayTime, view in
            delayAction("PHImageManager.requestExportSession", delayTime: delayTime, view: view) {
                _ = try AlbumEntry.requestExportSession(forToken: token, manager: PHImageManager(), forVideoAsset: PHAsset(), options: nil, exportPreset: "", resultHandler: { _, _ in })
            }
        }
    }

    private func requestImage() -> APIData {
        return APIData(title: "[PHImageManager requestImageForAsset:targetSize:contentMode:options:resultHandler:]") { delayTime, view in
            delayAction("PHImageManager.requestImage", delayTime: delayTime, view: view) {
                _ = try AlbumEntry.requestImage(forToken: token,
                                                manager: PHImageManager(),
                                                forAsset: PHAsset(),
                                                targetSize: CGSize(),
                                                contentMode: .aspectFill,
                                                options: nil,
                                                resultHandler: { _, _ in })
            }
        }
    }

    private func requestPlayerItem() -> APIData {
        return APIData(title: "[PHImageManager requestPlayerItemForVideo:options:resultHandler:]") { delayTime, view in
            delayAction("PHImageManager.requestPlayerItem", delayTime: delayTime, view: view) {
                _ = try AlbumEntry.requestPlayerItem(forToken: token, manager: PHImageManager(), forVideoAsset: PHAsset(), options: nil, resultHandler: { _, _ in })
            }
        }
    }

    @available(iOS, introduced: 14.0)
    private func createPickerViewControllerWithConfiguration() -> APIData {
        return APIData(title: "[PHPickerViewController initWithConfiguration:]") { delayTime, view in
            delayAction("PHPickerViewController.init", delayTime: delayTime, view: view) {
                _ = try AlbumEntry.createPickerViewControllerWithConfiguration(forToken: token,
                                                                               configuration: PHPickerConfiguration())
            }
        }
    }

    private func createImagePickerController() -> APIData {
        return APIData(title: "[UIImagePickerController init]") { delayTime, view in
            delayAction("UIImagePickerController.init", delayTime: delayTime, view: view) {
                _ = try AlbumEntry.createImagePickerController(forToken: token)
            }
        }
    }

    private func UIImageWriteToSavedPhotosAlbum() -> APIData {
        return APIData(title: "UIImageWriteToSavedPhotosAlbum") { delayTime, view in
            delayAction("UIImageWriteToSavedPhotosAlbum", delayTime: delayTime, view: view) {
                try AlbumEntry.UIImageWriteToSavedPhotosAlbum(forToken: token, UIImage(), nil, nil, nil)
            }
        }
    }

    private func UISaveVideoAtPathToSavedPhotosAlbum() -> APIData {
        return APIData(title: "UISaveVideoAtPathToSavedPhotosAlbum") { delayTime, view in
            delayAction("UISaveVideoAtPathToSavedPhotosAlbum", delayTime: delayTime, view: view) {
                try AlbumEntry.UISaveVideoAtPathToSavedPhotosAlbum(forToken: token, "", nil, nil, nil)
            }
        }
    }

    private func requestImageData() -> APIData {
        return APIData(title: "[PHImageManager requestImageDataForAsset:options:resultHandler:]") { delayTime, view in
            delayAction("PHImageManager.requestImageDatam", delayTime: delayTime, view: view) {
                _ = try AlbumEntry.requestImageData(forToken: token,
                                                    manager: PHImageManager(),
                                                    forAsset: PHAsset(),
                                                    options: nil,
                                                    resultHandler: { _, _, _, _ in })
            }
        }
    }

    @available(iOS, introduced: 13.0)
    private func requestImageDataAndOrientation() -> APIData {
        return APIData(title: "[PHImageManager requestImageDataAndOrientationForAsset:options:resultHandler:]") { delayTime, view in
            delayAction("PHImageManager.requestImageDataAndOrientation", delayTime: delayTime, view: view) {
                _ = try AlbumEntry.requestImageDataAndOrientation(forToken: token,
                                                                  manager: PHImageManager(),
                                                                  forAsset: PHAsset(),
                                                                  options: nil,
                                                                  resultHandler: { _, _, _, _ in })
            }
        }
    }
}

/// LocalNetwork
extension SensitivityAPIData {
    private func buildLocalNetwork() -> SectionData {
        var datas = [APIData]()
        datas.append(cfHostStartInfoResolution())
        datas.append(gethostbyname2())
        let section = SectionData(type: "LocalNetwork", apiDatas: datas)
        return section
    }
    
    private func cfHostStartInfoResolution() -> APIData {
        return APIData(title: "CFHostStartInfoResolution") { delayTime, view in
            delayAction("CFHostStartInfoResolution", delayTime: delayTime, view: view) {
                let host = CFHostCreateWithName(nil, "baidu.com" as CFString).takeRetainedValue()
                CFHostStartInfoResolution(host, .addresses, nil)
            }
        }
    }

    private func gethostbyname2() -> APIData {
        return APIData(title: "gethostbyname2") { delayTime, view in
            delayAction("gethostbyname2", delayTime: delayTime, view: view) {
                var ptr: CChar = CChar()
                let num: Int32 = 1
                Darwin.gethostbyname2(&ptr, num)
            }
        }
    }
}

/// RTC
extension SensitivityAPIData {
    private func buildRTC() -> SectionData {
        var datas = [APIData]()
        datas.append(startAudioCapture())
        datas.append(voIPJoin())
        datas.append(startVideoCapture())
        let section = SectionData(type: "RTC", apiDatas: datas)
        return section
    }

    private func startAudioCapture() -> APIData {
        return APIData(title: "checkTokenForStartAudioCapture") { delayTime, view in
            delayAction("checkTokenForStartAudioCapture", delayTime: delayTime, view: view) {
                _ = try RTCEntry.checkTokenForStartAudioCapture(token)
            }
        }
    }

    private func voIPJoin() -> APIData {
        return APIData(title: "checkTokenForVoIPJoin") { delayTime, view in
            delayAction("checkTokenForVoIPJoin", delayTime: delayTime, view: view) {
                _ = try RTCEntry.checkTokenForVoIPJoin(token)
            }
        }
    }

    private func startVideoCapture() -> APIData {
        return APIData(title: "checkTokenForStartVideoCapture") { delayTime, view in
            delayAction("checkTokenForStartVideoCapture", delayTime: delayTime, view: view) {
                _ = try RTCEntry.checkTokenForStartVideoCapture(token)
            }
        }
    }
}

#if !os(visionOS)
class LocationManager: NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func startMonitoringForRegion() {
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            let center = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            let region = CLCircularRegion(center: center, radius: 100, identifier: "MyRegion")
            region.notifyOnEntry = true
            region.notifyOnExit = true

            locationManager.startMonitoring(for: region)
        } else {
            print("Region monitoring is not available.")
        }
    }

    // CLLocationManagerDelegate methods
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered region: \(region.identifier)")
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited region: \(region.identifier)")
    }
}
#endif
