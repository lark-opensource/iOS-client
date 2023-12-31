//
//  LocationApi.swift
//  LarkSensitivityControl
//
//  Created by huanzhengjie on 2022/8/24.
//

import UIKit
import CoreLocation

public extension LocationApi {
    /// 外部注册自定义api使用的key值
    static var tag: String {
        "location"
    }
}

/// 使用期间使用位置：app前台运行定位权限，配置NSLocationWhenInUseUsageDescription；
/// 始终访问位置：app后台运行定位权限，配置NSLocationAlwaysAndWhenInUseUsageDescription；
/// 如果需要适配iOS11之前版本，还要配置NSLocationAlwaysUsageDescription。
public protocol LocationApi: SensitiveApi {
    /// CLLocationManager requestWhenInUseAuthorization
    static func requestWhenInUseAuthorization(forToken token: Token, manager: CLLocationManager) throws

    /// CLLocationManager requestLocation
    static func requestLocation(forToken token: Token, manager: CLLocationManager) throws

    /// CLLocationManager startUpdatingLocation
    static func startUpdatingLocation(forToken token: Token, manager: CLLocationManager) throws

    #if !os(visionOS)
    /// CLLocationManager startMonitoringSignificantLocationChanges
    static func startMonitoringSignificantLocationChanges(forToken token: Token, manager: CLLocationManager) throws

    /// CLLocationManager startMonitoring
    static func startMonitoring(forToken token: Token, manager: CLLocationManager, region: CLRegion) throws

    /// CLLocationManager startRangingBeacons
    static func startRangingBeacons(forToken token: Token,
                                    manager: CLLocationManager,
                                    region: CLBeaconRegion) throws

    /// CLLocationManager startRangingBeaconsSatisfyingConstraint
    @available(iOS 13.0, *)
    static func startRangingBeaconsSatisfyingConstraint(forToken token: Token,
                                                        manager: CLLocationManager,
                                                        constraint: CLBeaconIdentityConstraint) throws

    ///  CLLocationManager allowsBackgroundLocationUpdates
    static func allowsBackgroundLocationUpdates(forToken token: Token, manager: CLLocationManager) throws -> Bool

    ///  CLLocationManager startUpdatingHeading
    static func startUpdatingHeading(forToken token: Token, manager: CLLocationManager) throws

    /// CLLocationManager requestAlwaysAuthorization
    static func requestAlwaysAuthorization(forToken token: Token, manager: CLLocationManager) throws
    #endif
}
