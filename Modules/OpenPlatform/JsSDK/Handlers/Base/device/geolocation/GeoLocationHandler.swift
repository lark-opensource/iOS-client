//
//  GetGeolocationHandler.swift
//  Lark
//
//  Created by ChalrieSu on 16/03/2018.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import UIKit
import CoreTelephony
import Reachability
import LKCommonsLogging
import CoreLocation
import MapKit
import Contacts
import WebBrowser
import Swinject
import OPFoundation
import LarkOpenAPIModel

class GeoLocationHandler: NSObject {

    enum LocationService {
        case get, start, stop
    }

    static let logger = Logger.log(GeoLocationHandler.self, category: "Module.JSSDK")

    private let reach = Reachability()
    private let telephonyNetworkInfo = CTTelephonyNetworkInfo.lu.shared
    private var lastLocationService: LocationService?

    private typealias LocationRequestFail = (String) -> Void
    private typealias LocationRequestSuccess = () -> Void
    private var locationRequestBlocks: [(LocationRequestFail, LocationRequestSuccess)] = []

    private lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        _locationManager = locationManager
        return locationManager
    }()
    private var _locationManager: CLLocationManager?

    /// 最后一次定位位置
    private var lastLocationInfo: (CLLocation, CLPlacemark)?

    /// 定位时间间隔，因为高德iOS SDK不支持，暂时没有用到这个字段
    private var interval: Int = 0

    /// 场景ID,因为高德iOS SDK不支持，暂时没有用到这个字段
    private var sceneID: String = ""

    /// 单次定位回调
    var getLocationBlock: ( ([String: Any]) -> Void )?
    /// 开始定位回调
    var startLocationBlock: ( ([String: Any]) -> Void )?
    /// 停止定位回调
    var stopLocactionBlock: ( ([String: Any]) -> Void )?

    deinit {
        _locationManager?.delegate = nil
        _locationManager?.stopUpdatingLocation()
    }

    static func networkStatus() -> String {
        guard let reach = Reachability() else { return "unkown" }
        if reach.connection == .wifi {
            return "wifi"
        } else if reach.connection == .cellular {
            switch CTTelephonyNetworkInfo.lu.shared.lu.currentSpecificStatus {
            case .📶2G:
                return "2G"
            case .📶3G:
                return "3G"
            case .📶4G:
                return "4G"
            case .📶5G:
                return "5G"
            default:
                return "unknown"
            }
        }
        return "none"
    }

    //获取运营商
    private func operationType() -> String {
        if let carrier = self.telephonyNetworkInfo.subscriberCellularProvider, let name = carrier.carrierName {
            return name
        }
        return "unkown"
    }

    private func parse(location: CLLocation?, regesocode: CLPlacemark?, error: Error? = nil) -> [String: Any] {
        var result: [String: Any] = [:]

        if let error = error {
            let error: NSError = error as NSError
            result["errorCode"] = error.code
            result["errorMessage"] = error.localizedDescription
            GeoLocationHandler.logger.error("高德定位获取失败", error: error)
        } else {
            result["errorCode"] = 0
        }

        if let location = location, let regesocode = regesocode {
            result["errorCode"] = 0
            result["longitude"] = location.coordinate.longitude
            result["latitude"] = location.coordinate.latitude
            result["accuracy"] = location.horizontalAccuracy
            let address: String
            if let postalAddress = regesocode.postalAddress {
                address = CNPostalAddressFormatter().string(from: postalAddress)
            } else {
                address = ""
            }
            result["address"] = address
            result["province"] = regesocode.administrativeArea ?? ""
            result["city"] = regesocode.locality ?? ""
            result["district"] = regesocode.subLocality ?? ""
            result["road"] = "\(regesocode.thoroughfare ?? "")-\(regesocode.subThoroughfare ?? "")"
            result["time"] = location.timestamp.timeIntervalSince1970
            result["netType"] = GeoLocationHandler.networkStatus()
            result["operatorType"] = operationType()
        } else {
            let errorMessage = "定位获取失败, location或者regesocode为空"
            GeoLocationHandler.logger.error(errorMessage)
            result["errorCode"] = 1
            result["errorMessage"] = errorMessage
        }
        return result
    }
    
    private func requestLocation(type: LocationService, shouldUseCache: Bool, successCallback: @escaping () throws -> Void) {
        let enable = CLLocationManager.locationServicesEnabled()
        let status = CLLocationManager.authorizationStatus()
        let onError: LocationRequestFail = { [weak self] errorCode in
            var result: [String: Any] = [:]
            result["errorCode"] = 1
            result["errorMessage"] = errorCode
            self?.callBack(result: result)
        }
        let onSuccess = { [weak self] in
            guard let self = self else { return }
            if shouldUseCache {
                if let lastLocationInfo = self.lastLocationInfo {
                    let result = self.parse(location: lastLocationInfo.0, regesocode: lastLocationInfo.1)
                    if type == .get {
                        self.getLocationBlock?(result)
                    } else if type == .start {
                        self.startLocationBlock?(result)
                    }
                    return
                }
            }
            do {
                try successCallback()
            } catch let error {
                let errString = (error as? OpenAPIError)?.errnoInfo["errString"] as? String
                onError(errString ?? OpenAPICommonErrno.internalError.errString)
            }
        }
        if !enable || status == .denied || status == .restricted {
            onError("定位获取失败, 无权限");     // 不可用
        } else if status == .notDetermined {
            do {
                try OPSensitivityEntry.requestWhenInUseAuthorization(forToken: .geoLocationHandlerRequestLocation, manager: self.locationManager)
                locationRequestBlocks.append((onError, onSuccess))  // 未决定
            } catch let error {
                let errString = (error as? OpenAPIError)?.errnoInfo["errString"] as? String
                onError(errString ?? OpenAPICommonErrno.internalError.errString)
            }
        } else {
            onSuccess()  // 可用
        }
    }

    func getLocation(shouldUseCache: Bool) {
        self.lastLocationService = .get
        requestLocation(type: .get, shouldUseCache: shouldUseCache) {
            try OPSensitivityEntry.requestLocation(forToken: .geoLocationHandlerGetLocation, manager: self.locationManager)
        }
    }

    func startLocation(shouldUseCache: Bool, interval: Int, sceneID: String) {
        lastLocationService = .start
        requestLocation(type: .start, shouldUseCache: shouldUseCache) {
            self.interval = interval
            self.sceneID = sceneID
            try OPSensitivityEntry.startUpdatingLocation(forToken: .geoLocationHandlerStartLocation, manager: self.locationManager)
        }
    }

    func stopLocation(sceneID: String) {
        lastLocationService = .stop

        locationManager.stopUpdatingLocation()
        stopLocactionBlock?(["sceneId": sceneID])
    }

    private func callBack(result: [String: Any]) {
        if let lastLocationService = lastLocationService {
            switch lastLocationService {
            case .get:
                getLocationBlock?(result)
            case .start:
                startLocationBlock?(result)
            case .stop:
                break
            }
        }
    }
}

extension GeoLocationHandler: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            self.callBack(result: parse(location: nil, regesocode: nil, error: nil))
            return
        }
        let geocodeCompletionHandler: CLGeocodeCompletionHandler = { [weak self] (placeMark, error) in
            guard let self = self else { return }
            if let placeMark = placeMark?.last {
                self.lastLocationInfo = (location, placeMark)
            }
            let result = self.parse(location: location, regesocode: placeMark?.last, error: error)
            self.callBack(result: result)
        }
        do {
            try OPSensitivityEntry.reverseGeocodeLocation(forToken: .jsSDKGeoLocationHandlerRequestLocationReverseGeocode,
                                                         geocoder: CLGeocoder(),
                                                         location: location,
                                                         completionHandler: geocodeCompletionHandler)
        } catch {
            geocodeCompletionHandler(nil, error)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        var result: [String: Any] = [:]
        let error: NSError = error as NSError
        result["errorCode"] = error.code
        result["errorMessage"] = error.localizedDescription
        GeoLocationHandler.logger.error("苹果定位获取失败", error: error)
        callBack(result: result)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .notDetermined {
            return
        }
        if status == .denied || status == .restricted {
            locationRequestBlocks.forEach { (onError, _) in
                onError("定位获取失败, 无权限")
            }
        } else {
            locationRequestBlocks.forEach { (_, onSuccess) in
                onSuccess()
            }
        }
        locationRequestBlocks.removeAll()
    }
}
