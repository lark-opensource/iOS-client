//
//  AppleLocationService.swift
//  LarkCoreLocation
//
//  Created by zhangxudong on 3/31/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import CoreLocation
import Foundation
import LKCommonsLogging
import LarkPrivacySetting
#if canImport(AMapFoundationKit)
import AMapFoundationKit
#endif
/// Apple 定位能力
final class AppleLocationService: NSObject, LocationService {
    private static let logger = Logger.log(AppleLocationService.self, category: "LarkCoreLocation")
    private let locationManager = CLLocationManager()
    let serviceType: LocationServiceType = .apple
    var distanceFilter: CLLocationDistance {
        get {
            return locationManager.distanceFilter
        }
        set {
            Self.logger.info("AppleLocationService set distanceFilter oldValue: \(distanceFilter), newValue: \(newValue)")
            locationManager.distanceFilter = newValue
        }
    }

    var desiredAccuracy: CLLocationAccuracy {
        get {
            return locationManager.desiredAccuracy
        }
        set {
            Self.logger.info("AppleLocationService set desiredAccuracy oldValue: \(desiredAccuracy), newValue: \(newValue)")
            locationManager.desiredAccuracy = newValue
        }
    }

    var pausesLocationUpdatesAutomatically: Bool {
        get {
            return locationManager.pausesLocationUpdatesAutomatically
        }
        set {
            let log = "AppleLocationService set pausesLocationUpdatesAutomatically oldValue: \(pausesLocationUpdatesAutomatically), newValue: \(newValue)"
            Self.logger.info(log)
            locationManager.pausesLocationUpdatesAutomatically = newValue
        }
    }

    weak var delegate: LocationServiceDelegate?

    override init() {
        super.init()
        configDefaultValue()
        Self.logger.info("AppleLocationService init")
    }

    func configDefaultValue() {
        locationManager.delegate = self
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    func startUpdatingLocation() {
        Self.logger.info("AppleLocationService startUpdatingLocation")
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        Self.logger.info("AppleLocationService stopUpdatingLocation")
        locationManager.stopUpdatingLocation()
    }

    func isAdminAllowAmap() -> Bool {
        let result = LarkLocationAuthority.checkAmapAuthority()
        Self.logger.info("AppleLocationService isAdminAllowAmap result:\(result)")
        return result
    }
}

extension AppleLocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.locationService(self, didFailWithError: error)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Self.logger.info("AppleLocationService received didChangeAuthorization status:\(status)")
        delegate?.locationService(self, locationManagerDidChangeAuthorization: manager)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
       let larkLocations = locations.map { aLocation -> LarkLocation in
            var location = aLocation
            /// 坐标系问题整理 https://bytedance.feishu.cn/wiki/wikcnVLrAbyhKbT9JmHwL3wKPAh
            /// 为了合规&坐标的消费在飞书/lark内部消费尽量闭环
            /// 在飞书上除了台湾地区的的坐标返回为gcj02
            /// 在Lark上所有的坐标尽量为wgs84
            var locationType: LocationFrameType = .wjs84
    #if canImport(AMapFoundationKit)
            if isAdminAllowAmap() {
                Self.logger.info("used amap service")
                let gcj02Coordinate = AMapCoordinateConvert(location.coordinate, .GPS)
                /// 是否有高德数据，如果有证明为中国大陆/港/澳 可以转换为02 否则为台湾/海外 使用84坐标
                if AMapDataAvailableForCoordinate(gcj02Coordinate) {
                    location = location.copyAndSet(coordinate: gcj02Coordinate)
                    locationType = .gcj02
                }
            }
    #endif
            let larkLocation = LarkLocation(location: location,
                                            locationType: locationType,
                                            serviceType: .apple,
                                            time: Date(),
                                            authorizationAccuracy: shareLocationAuth().authorizationAccuracy())
            return larkLocation
        }
        Self.logger.info("AppleLocationService received update locations \(locations), transform larkLocations: \(larkLocations)")
        delegate?.locationService(self, didUpdate: larkLocations)
    }
}

private extension CLLocation {
    func copyAndSet(coordinate: CLLocationCoordinate2D) -> CLLocation {
        if #available(iOS 15.4, *), let sourceInfo = sourceInformation {
            return CLLocation(coordinate: coordinate,
                              altitude: altitude,
                              horizontalAccuracy: horizontalAccuracy,
                              verticalAccuracy: verticalAccuracy,
                              course: course,
                              courseAccuracy: courseAccuracy,
                              speed: speed,
                              speedAccuracy: speedAccuracy,
                              timestamp: timestamp,
                              sourceInfo: sourceInfo)
        } else if #available(iOS 13.4, *) {
            return CLLocation(coordinate: coordinate,
                              altitude: altitude,
                              horizontalAccuracy: horizontalAccuracy,
                              verticalAccuracy: verticalAccuracy,
                              course: course,
                              courseAccuracy: courseAccuracy,
                              speed: speed,
                              speedAccuracy: speedAccuracy,
                              timestamp: timestamp)
        }
        return CLLocation(coordinate: coordinate,
                          altitude: altitude,
                          horizontalAccuracy: horizontalAccuracy,
                          verticalAccuracy: verticalAccuracy,
                          course: course,
                          speed: speed,
                          timestamp: timestamp)
    }
}
