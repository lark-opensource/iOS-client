//
//  OpenLocationManager.swift
//  OPPlugin
//
//  Created by laisanpin on 2021/5/19.
//

import Foundation

import CoreLocation
import LKCommonsLogging
import OPPluginBiz
import LarkOpenPluginManager
import LarkOpenAPIModel
import ECOProbeMeta
import OPPluginManagerAdapter
import LarkCoreLocation
import LarkContainer
import OPFoundation

public typealias OPContinueLocationCompletionBlock = (_ error: OpenAPIError?) -> Void

public typealias OPLocationUpdateBlock = (_ location: CLLocation, _ locations:[CLLocation], _ coordinateSytemType: OPCoordinateSystemType) -> Void

public typealias OPLocationRequestAuthorizeBlock = (_ authorization: Bool)-> Void

public enum OPCoordinateSystemType: String {
    case WGS84 = "wgs84" // WGS84坐标系
    case GCJ02 = "gcj02"// GCJ-02坐标
}

//定位精度(iOS14以上才有)
public enum OPAccuracyAuthorization: Int {
    case unknow = -1
    case fullAccuracy = 0
    case reducedAccuracy = 1
}

final class OpenPluginContinueLocationManager: NSObject {
    private static let logger = Logger.oplog(OpenPluginContinueLocationManager.self, category: "OpenPluginContinueLocationManager")
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.pausesLocationUpdatesAutomatically = false
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        return manager
    }()
    /// 定位权限相关
    @InjectedSafeLazy private var locationAuth: LocationAuthorization // Global
    
    //是否已经开始持续定位
    private var startLocationUpdate = false

    private var appUniqueID: OPAppUniqueID

    private var coordinateSystemType = OPCoordinateSystemType.WGS84

    private var locationUpdateBlock: OPLocationUpdateBlock?

    private var requestLocationAuthorizationBlock: OPLocationRequestAuthorizeBlock?
    private var accuracyAuthorization: OPAccuracyAuthorization {
        let accuracyAuthorization: OPAccuracyAuthorization
        if #available(iOS 14, *) {
            accuracyAuthorization = OPAccuracyAuthorization(rawValue: locationManager.accuracyAuthorization.rawValue) ?? .unknow
        } else {
            accuracyAuthorization = .unknow
        }
        return accuracyAuthorization
    }

    public func startLocationUpdate(accuracy: String,
                                    coordinateSystemType: String,
                                    locationUpdateCallback: @escaping OPLocationUpdateBlock,
                                    completion: @escaping OPContinueLocationCompletionBlock) {
       
        let desiredAccuracy = accuracy == "best" ? kCLLocationAccuracyBest : kCLLocationAccuracyHundredMeters
        self.coordinateSystemType = OPCoordinateSystemType(rawValue: coordinateSystemType) ?? .WGS84
        Self.logger.info("startLocationUpdate params: <accuracy: \(accuracy), coordinateSystemType: \(coordinateSystemType), desiredAccuracy: \(desiredAccuracy)>")
        if self.coordinateSystemType == .GCJ02,
           !OPLocaionOCBridge.canConvertToGCJ02() {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setMonitorMessage("cannot use gcj02 type without amap")
            completion(error)
            return
        }

        locationManager.desiredAccuracy = desiredAccuracy
        locationUpdateBlock = locationUpdateCallback

        let wifiStatus = EMADeviceHelper.getWiFiStatus(with: .openPluginContinueLocationManagerStartLocationUpdateMonitor)
        Self.logger.info("startLocationUpdate monitor getWiFiStatus: \(wifiStatus)")
        let monitor = OPMonitor(EPMClientOpenPlatformApiLocationCode.start_location_update)
            .addMap(["desiredAccuracy":String(describing:desiredAccuracy),
                     "wifiStatus":String(describing: wifiStatus),
                     "app_type":OPAppTypeToString(appUniqueID.appType),
                     "app_id":appUniqueID.appID,
                     "coordinateSystemType" : String(describing:coordinateSystemType),
                     "accuracyAuthorization":String(describing:accuracyAuthorization)])

        requestAuthoriztion {[weak self] (auth) in
            guard let `self` = self else {
                monitor.addMap(["result":"OpenPluginContinueLocationManager is nil"]).flush()
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setMonitorMessage("self is nil When call API")
                completion(error)
                return
            }

            if !auth {
                monitor.addMap(["result":"location systemAuthDeny"]).flush()
                let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                    .setMonitorMessage("location systemAuthDeny")
                completion(error)
                return
            }

            monitor.addMap(["result":"success"]).flush()
            self.startLocationUpdate = true
            do {
                try OPSensitivityEntry.startUpdatingLocation(forToken: .continueLocationManagerStartLocationUpdate, manager: self.locationManager)
                self.updateLocationAccessStatus(isUsing: true)
                completion(nil)
            } catch let error as OpenAPIError {
                completion(error)
            } catch let error {
                Self.logger.error("should not throw error which is not kind of OpenAPIError, error:\(error)")
                completion(OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    .setMonitorMessage(error.localizedDescription))
            }
        }
    }

    public func stopLocationUpdate(completion: @escaping OPContinueLocationCompletionBlock) {
        Self.logger.info("stopLocationUpdate")
        let wifiStatus = EMADeviceHelper.getWiFiStatus(with: .openPluginContinueLocationManagerStartLocationUpdateMonitor)
        let monitor = OPMonitor(EPMClientOpenPlatformApiLocationCode.stop_location_update)
            .addMap(["wifiStatus":String(describing:wifiStatus),
                     "app_type":OPAppTypeToString(appUniqueID.appType),
                     "app_id":appUniqueID.appID])

        requestAuthoriztion {[weak self] (auth) in
            guard let `self` = self else {
                monitor.addMap(["result":"OpenPluginContinueLocationManager is nil"]).flush()
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setMonitorMessage("self is nil When call API")
                completion(error)
                return
            }

            if !auth {
                monitor.addMap(["result":"location systemAuthDeny"]).flush()
                let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                    .setMonitorMessage("location systemAuthDeny")
                completion(error)
                return
            }

            monitor.addMap(["result":"success"]).flush()
            self.startLocationUpdate = false
            self.locationManager.stopUpdatingLocation()
            self.updateLocationAccessStatus(isUsing: false)
            completion(nil)
        }
    }

    private func requestAuthoriztion(_ completion: @escaping OPLocationRequestAuthorizeBlock) {
        let enable = locationAuth.locationServicesEnabled()
        let status = CLLocationManager.authorizationStatus()
        if !enable || status == .denied || status == .restricted {
            completion(false)
        } else if (status == .notDetermined) {
            do {
                try OPSensitivityEntry.requestWhenInUseAuthorization(forToken: .continueLocationManagerRequestAuthoriztion, manager: locationManager)
                requestLocationAuthorizationBlock = completion
            } catch _ {
                completion(false)
            }
        } else {
            completion(true)
        }
    }

    private func targetLocationFromLocation(_ location: CLLocation) -> CLLocation {
        if coordinateSystemType == .GCJ02 {
            // WGS84 -> GCJ-02
            if OPLocaionOCBridge.canConvertToGCJ02() {
                return CLLocation(coordinate: OPLocaionOCBridge.bdp_convertLocation(toGCJ02: location.coordinate),
                                  altitude: location.altitude,
                                  horizontalAccuracy: location.horizontalAccuracy,
                                  verticalAccuracy: location.verticalAccuracy,
                                  course: location.course,
                                  speed: location.speed,
                                  timestamp: location.timestamp)
            } else {
                //不能转换则设置成wgs84坐标系
                coordinateSystemType = .WGS84
                Self.logger.info("cannot conver WGS84 to GCJ02")
            }
        }
        return location
    }

    private func updateLocationAccessStatus(isUsing: Bool) {
        OPLocationPrivacyAccessStatusManager.shareInstance().updateContinueLocationAccessStatus(isUsing)
    }

    deinit {
        if startLocationUpdate {
            locationManager.stopUpdatingLocation()
            updateLocationAccessStatus(isUsing: false)
        }
    }

    convenience init(uniqueID: OPAppUniqueID) {
        self.init(uniqueID)
        self.addListener()
    }

    private init(_ uniqueID: OPAppUniqueID) {
        appUniqueID = uniqueID
    }
}

extension OpenPluginContinueLocationManager: CLLocationManagerDelegate {

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            Self.logger.error("didUpdateLocations location, but locations is empty")
            return
        }
        let logs = locations.map({ value -> String in
            let locationString = "coordinateSystemType: wgs84 " + String(describing: value)
            if #available(iOS 15.0, *), let sourceInfo = value.sourceInformation {
                return locationString + " isSimulatedBySoftware: \(sourceInfo.isSimulatedBySoftware), isProducedByAccessory: \(sourceInfo.isProducedByAccessory)"
            }
            return locationString
        })
        Self.logger.info("didUpdateLocations location: \(logs)")
        if let locationUpdateCallback = locationUpdateBlock {
            locationUpdateCallback(targetLocationFromLocation(location), locations.map({
                targetLocationFromLocation($0)
            }), coordinateSystemType)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Self.logger.error("didFailWithError error: \(error)")
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Self.logger.info("didChangeAuthorization status: \(status), accuracyAuthorization")
        if status == .notDetermined {
            return
        }

        if let locationCallback = requestLocationAuthorizationBlock {
            if status == .denied || status == .restricted {
                locationCallback(false)
            } else {
                locationCallback(true)
            }
            requestLocationAuthorizationBlock = nil
        }
    }
}

private extension OpenPluginContinueLocationManager {
    private func addListener() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppEnterBackground(_:)), name: NSNotification.Name(rawValue: kBDPEnterBackgroundNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppEnterForeground(_:)), name: NSNotification.Name(rawValue: kBDPEnterForegroundNotification), object: nil)
    }

    @objc
    private func handleAppEnterBackground(_ notify: Notification) {
        guard startLocationUpdate else {
            return
        }

        if let uniqueID = notify.userInfo?[kBDPUniqueIDUserInfoKey] as? OPAppUniqueID,
           uniqueID.fullString == appUniqueID.fullString {
            Self.logger.info("microapp uniqueID:\(uniqueID.fullString) handleAppEnterBackground stopUpdatingLocation")
            locationManager.stopUpdatingLocation()
            updateLocationAccessStatus(isUsing: false)
        }
    }

    @objc
    private func handleAppEnterForeground(_ notify: Notification) {
        guard startLocationUpdate else {
            return
        }

        if let uniqueID = notify.userInfo?[kBDPUniqueIDUserInfoKey] as? OPAppUniqueID,
           uniqueID.fullString == appUniqueID.fullString {
            
            do {
                try OPSensitivityEntry.startUpdatingLocation(forToken: .continueLocationManagerHandleAppEnterForeground, manager: locationManager)
                Self.logger.info("microapp uniqueID:\(uniqueID.fullString) handleAppEnterForeground startUpdatingLocation success")
            } catch let error {
                Self.logger.error("microapp uniqueID:\(uniqueID.fullString) handleAppEnterForeground startUpdatingLocation failed", error: error)
            }
            updateLocationAccessStatus(isUsing: true)
        }
    }
}
