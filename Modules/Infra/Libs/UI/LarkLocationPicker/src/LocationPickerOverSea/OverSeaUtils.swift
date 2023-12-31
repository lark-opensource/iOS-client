//
//  OverSeaUtils.swift
//  LarkLocationPicker
//
//  Created by 姚启灏 on 2020/5/18.
//

import Foundation
import MapKit
import LKCommonsLogging

public class FeatureUtils: NSObject {
    private static let logger = Logger.log(FeatureUtils.self, category: "LocationPicker.FeatureUtils")

    /// 海外不需要使用该方法
    /// No need to use this method overseas
    @objc public static func convertWGS84ToGCJ02(coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        return coordinate
    }

    /// 设置高德地图API key，海外版不使用高德
    /// Set Gaode map API key, overseas version does not use Gaode
    public static func setAMapAPIKey() { }

    public static func isAdminAllowAmap() -> Bool {
        return false
    }

    public static func AMapDataAvailableForCoordinate(_ location: CLLocationCoordinate2D) -> Bool {
        return false
    }

    @objc public static func isAMap() -> Bool {
        FeatureUtils.logger.info("Is AMap \(false)")
        return false
    }
}
