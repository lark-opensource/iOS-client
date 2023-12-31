//
//  LocationWrapper.swift
//  LarkSensitivityControl
//
//  Created by huanzhengjie on 2022/8/24.
//

import UIKit
import CoreLocation

final class LocationWrapper: NSObject, LocationApi {
    /// CLLocationManager requestWhenInUseAuthorization
    static func requestWhenInUseAuthorization(forToken token: Token, manager: CLLocationManager) throws {
        manager.requestWhenInUseAuthorization()
    }

    /// CLLocationManager requestLocation
    static func requestLocation(forToken token: Token, manager: CLLocationManager) throws {
        manager.requestLocation()
    }

    /// CLLocationManager startUpdatingLocation
    static func startUpdatingLocation(forToken token: Token, manager: CLLocationManager) throws {
        manager.startUpdatingLocation()
    }

    #if !os(visionOS)
    /// CLLocationManager startMonitoringSignificantLocationChanges
    static func startMonitoringSignificantLocationChanges(forToken token: Token, manager: CLLocationManager) throws {
        manager.startMonitoringSignificantLocationChanges()
    }

    /// CLLocationManager startMonitoring
    static func startMonitoring(forToken token: Token, manager: CLLocationManager, region: CLRegion) throws {
        manager.startMonitoring(for: region)
    }

    /// CLLocationManager startRangingBeacons
    static func startRangingBeacons(forToken token: Token, manager: CLLocationManager, region: CLBeaconRegion) throws {
        manager.startRangingBeacons(in: region)
    }

    /// CLLocationManager startRangingBeaconsSatisfyingConstraint
    @available(iOS 13.0, *)
    static func startRangingBeaconsSatisfyingConstraint(forToken token: Token,
                                                        manager: CLLocationManager,
                                                        constraint: CLBeaconIdentityConstraint) throws {
        manager.startRangingBeacons(satisfying: constraint)
    }

    ///  CLLocationManager allowsBackgroundLocationUpdates
    static func allowsBackgroundLocationUpdates(forToken token: Token, manager: CLLocationManager) throws -> Bool {
        return manager.allowsBackgroundLocationUpdates
    }

    ///  CLLocationManager startUpdatingHeading
    static func startUpdatingHeading(forToken token: Token, manager: CLLocationManager) throws {
        manager.startUpdatingHeading()
    }

    /// CLLocationManager requestAlwaysAuthorization
    static func requestAlwaysAuthorization(forToken token: Token, manager: CLLocationManager) throws {
        manager.requestAlwaysAuthorization()
    }
    #endif
}
