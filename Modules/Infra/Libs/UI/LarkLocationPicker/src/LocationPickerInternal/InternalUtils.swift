//
//  InternalUtils.swift
//  LarkLocationPicker
//
//  Created by 姚启灏 on 2020/5/18.
//

import Foundation
import MapKit
import AMapSearchKit
import LKCommonsLogging
import LarkSetting
import LarkPrivacySetting

public final class FeatureUtils: NSObject {
    private static let logger = Logger.log(FeatureUtils.self, category: "LocationPicker.FeatureUtils")

    /// 海外不需要使用该方法
    /// No need to use this method overseas
    @objc public static func convertWGS84ToGCJ02(coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        guard Self.isAdminAllowAmap() else {
            return coordinate
        }
        return AMapCoordinateConvert(coordinate, AMapCoordinateType.GPS)
    }

    /// 设置高德地图API key，海外版不使用高德
    /// Set Gaode map API key, overseas version does not use Gaode
    /// 设置高德地图API key
    public static func setAMapAPIKey() {
        AMapServices.shared().enableHTTPS = true
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        let validBundleIDs = ["com.bytedance.ee.lark"] //飞书
        let isOnAllowed = (validBundleIDs.contains(bundleID))
        if FeatureGatingManager.realTimeManager.featureGatingValue(with: "core.location.use_old_amap_key"), isOnAllowed {  //Global 和用户数据无关，按照版本来控制fg的value
            let oldAmapKey = "3e7a6c04c43648a8f174f01ee35b1cdd"
            AMapServices.shared().apiKey = oldAmapKey
            Self.logger.info("FeatureUtils use old amap key \(oldAmapKey)")
            return
        }
        if let key = Bundle.main.infoDictionary?["AMAP_KEY"] as? String {
            AMapServices.shared().apiKey = key
            Self.logger.info("FeatureUtils setupAMapKey \(key)")
        } else {
            Self.logger.info("AMAP_KEY is null")
            assertionFailure("需要在info里添加amapkey")
        }
    }

    /// admin后台高德SDK开关
    public static func isAdminAllowAmap() -> Bool {
        let result = LarkLocationAuthority.checkAmapAuthority()
        FeatureUtils.logger.info("FeatureUtils isAdminAllowAmap result:\(result)")
        return result
    }

    public static func AMapDataAvailableForCoordinate(_ location: CLLocationCoordinate2D) -> Bool {
        guard Self.isAdminAllowAmap() else {
            return false
        }
        let result = AMapSearchKit.AMapDataAvailableForCoordinate(location)
        FeatureUtils.logger.info("AMap Data Available For Coordinate: \(result)")
        return result
    }

    @objc public static func isAMap() -> Bool {
        FeatureUtils.logger.info("Is AMap \(true)")
        return true
    }
}
