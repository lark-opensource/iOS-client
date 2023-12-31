//
//  LocationEntry.swift
//  LarkSensitivityControl
//
//  Created by huanzhengjie on 2022/8/24.
//

import UIKit
import CoreLocation

@objc
final public class LocationEntry: NSObject, LocationApi {

    private static func getService() -> LocationApi.Type {
        if let service = LSC.getService(forTag: tag) as? LocationApi.Type {
            return service
        }
        return LocationWrapper.self
    }

    /// CLLocationManager requestWhenInUseAuthorization
    @objc
    public static func requestWhenInUseAuthorization(forToken token: Token, manager: CLLocationManager) throws {
        let context = Context([AtomicInfo.Location.requestWhenInUseAuthorization.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().requestWhenInUseAuthorization(forToken: token, manager: manager)
    }

    /// CLLocationManager requestLocation
    @objc
    public static func requestLocation(forToken token: Token, manager: CLLocationManager) throws {
        let context = Context([AtomicInfo.Location.requestLocation.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().requestLocation(forToken: token, manager: manager)
    }

    /// CLLocationManager startUpdatingLocation
    @objc
    public static func startUpdatingLocation(forToken token: Token, manager: CLLocationManager) throws {
        let context = Context([AtomicInfo.Location.startUpdatingLocation.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().startUpdatingLocation(forToken: token, manager: manager)
    }

    #if !os(visionOS)
    /// CLLocationManager startMonitoringSignificantLocationChanges
    @objc
    public static func startMonitoringSignificantLocationChanges(forToken token: Token,
                                                                 manager: CLLocationManager) throws {
        let context = Context([AtomicInfo.Location.startMonitoringSignificantLocationChanges.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().startMonitoringSignificantLocationChanges(forToken: token, manager: manager)
    }

    /// CLLocationManager startMonitoring
    @objc
    public static func startMonitoring(forToken token: Token, manager: CLLocationManager, region: CLRegion) throws {
        let context = Context([AtomicInfo.Location.startMonitoring.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().startMonitoring(forToken: token, manager: manager, region: region)
    }

    /// CLLocationManager startRangingBeacons
    @objc
    public static func startRangingBeacons(forToken token: Token,
                                           manager: CLLocationManager,
                                           region: CLBeaconRegion) throws {
        let context = Context([AtomicInfo.Location.startRangingBeacons.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().startRangingBeacons(forToken: token, manager: manager, region: region)
    }

    /// CLLocationManager startRangingBeaconsSatisfyingConstraint
    @objc
    @available(iOS 13.0, *)
    public static func startRangingBeaconsSatisfyingConstraint(forToken token: Token,
                                                               manager: CLLocationManager,
                                                               constraint: CLBeaconIdentityConstraint) throws {
        let context = Context([AtomicInfo.Location.startRangingBeaconsSatisfyingConstraint.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().startRangingBeaconsSatisfyingConstraint(forToken: token,
                                                                 manager: manager,
                                                                 constraint: constraint)
    }

    ///  CLLocationManager allowsBackgroundLocationUpdates
    public static func allowsBackgroundLocationUpdates(forToken token: Token, manager: CLLocationManager) throws -> Bool {
        let context = Context([AtomicInfo.Location.allowsBackgroundLocationUpdates.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().allowsBackgroundLocationUpdates(forToken: token, manager: manager)
    }

    ///  CLLocationManager startUpdatingHeading
    public static func startUpdatingHeading(forToken token: Token, manager: CLLocationManager) throws {
        let context = Context([AtomicInfo.Location.startUpdatingHeading.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().startUpdatingHeading(forToken: token, manager: manager)
    }

    /// CLLocationManager requestAlwaysAuthorization
    @objc
    public static func requestAlwaysAuthorization(forToken token: Token, manager: CLLocationManager) throws {
        let context = Context([AtomicInfo.Location.requestAlwaysAuthorization.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().requestAlwaysAuthorization(forToken: token, manager: manager)
    }
    #endif
}
