//
//  LarkSensitivityControl+Location.swift
//  OPFoundation
//
//  Created by zhangxudong.999 on 2022/11/30.
//

import Foundation
import CoreLocation
import LarkSensitivityControl
extension OPSensitivityEntry {
    
    /// OP requestWhenInUseAuthorization
    /// - throw: error as OpenAPIError
    @objc public static func requestWhenInUseAuthorization(forToken token: OPSensitivityEntryToken, manager: CLLocationManager) throws {
        try LocationEntry.requestWhenInUseAuthorization(forToken: token.psdaToken, manager: manager)
    }

    /// OP requestLocation
    /// - throw: error as OpenAPIError
    @objc public static func requestLocation(forToken token: OPSensitivityEntryToken, manager: CLLocationManager) throws {
        try LocationEntry.requestLocation(forToken: token.psdaToken , manager: manager)
    }

    /// OP startUpdatingLocation
    /// - throw: error as OpenAPIError
    @objc public static func startUpdatingLocation(forToken token: OPSensitivityEntryToken, manager: CLLocationManager) throws {
        try LocationEntry.startUpdatingLocation(forToken: token.psdaToken, manager: manager)
    }

    /// OP startRangingBeacons
    /// - throw: error as OpenAPIError
    @objc
    public static func startRangingBeacons(forToken token: OPSensitivityEntryToken,
                                           manager: CLLocationManager,
                                           region: CLBeaconRegion) throws {
        try LocationEntry.startRangingBeacons(forToken: token.psdaToken, manager: manager, region: region)
    }
}

