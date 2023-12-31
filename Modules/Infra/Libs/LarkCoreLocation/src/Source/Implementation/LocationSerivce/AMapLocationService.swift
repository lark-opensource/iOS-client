//
//  AMapLocationService.swift
//  LarkCoreLocation
//
//  Created by zhangxudong on 3/31/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

#if canImport(AMapLocationKit)
import AMapLocationKit
import Foundation
import LKCommonsLogging
import LarkSetting
/// 高德地图 定位能力
final class AMapLocationService: NSObject,
                           LocationService,
                           LocationTaskSetting {

    private static let logger = Logger.log(AMapLocationService.self, category: "LarkCoreLocation")
    private static let setupAMapKey: String = {
        AMapServices.shared().enableHTTPS = true
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        let validBundleIDs = ["com.bytedance.ee.lark"] //飞书
        let isOnAllowed = (validBundleIDs.contains(bundleID))
        if FeatureGatingManager.realTimeManager.featureGatingValue(with: "core.location.use_old_amap_key"), isOnAllowed { //Global 和用户数据无关，按照版本来控制fg的value
            let oldAmapKey = "3e7a6c04c43648a8f174f01ee35b1cdd"
            AMapServices.shared().apiKey = oldAmapKey
            logger.info("use old amap key \(oldAmapKey)")
            return oldAmapKey
        }
        guard let key = Bundle.main.infoDictionary?["AMAP_KEY"] as? String, !key.isEmpty else {
            assertionFailure("需要在info里添加amapkey")
            return ""
        }
        AMapServices.shared().apiKey = key
        return key
    }()

    private let locationManager: AMapLocationManager = {
        let key = setupAMapKey
        logger.info("AMapLocationService setupAMapKey \(key)")
        // https://lbs.amap.com/agreement/news/sdkhgsy
        // 高德定位8.0以后：需要弹窗以后设置。
        // [AMapLocationManager updatePrivacyAgree:AMapPrivacyAgreeStatusDidAgree];
        // [AMapLocationManager updatePrivacyShow:AMapPrivacyShowStatusDidShow privacyInfo:AMapPrivacyInfoStatusDidContain];
        // 否则初始化失败，manager处于<uninitialized>状态。调所有方法不起作用
        AMapLocationManager.updatePrivacyShow(.didShow, privacyInfo: .didContain)
        AMapLocationManager.updatePrivacyAgree(.didAgree)
        let manager = AMapLocationManager()
        logger.info("AMapLocationService manager: \(String(describing: manager.description)) identifier: \(AMapServices.shared().identifier ?? "")")
        return manager
    }()

    var serviceType: LocationServiceType { .aMap }
    weak var delegate: LocationServiceDelegate?

    var distanceFilter: CLLocationDistance {
        get {
            return locationManager.distanceFilter
        }
        set {
            Self.logger.info("AMapLocationService set distanceFilter oldValue: \(distanceFilter), newValue: \(newValue)")
            locationManager.distanceFilter = newValue
        }
    }

    var desiredAccuracy: CLLocationAccuracy {
        get {
            return locationManager.desiredAccuracy
        }
        set {
            Self.logger.info("AMapLocationService set desiredAccuracy oldValue: \(desiredAccuracy), newValue: \(newValue)")
            locationManager.desiredAccuracy = newValue
        }
    }

    var pausesLocationUpdatesAutomatically: Bool {
        get {
            return locationManager.pausesLocationUpdatesAutomatically
        }
        set {
            let log = "AMapLocationService set pausesLocationUpdatesAutomatically oldValue: \(pausesLocationUpdatesAutomatically), newValue: \(newValue)"
            Self.logger.info(log)
            locationManager.pausesLocationUpdatesAutomatically = newValue
        }
    }

    override init() {
        super.init()
        configDefaultValue()
        Self.logger.info("AMapLocationService init")
    }

    func configDefaultValue() {
        locationManager.delegate = self
        locationManager.pausesLocationUpdatesAutomatically = false
        /// 检测是否存在虚拟定位风险
        /// 为了防止高德坑dad（或者是别的tricky 手段触发高德坑dad），把这个开关加上。真刺激！！！
        locationManager.detectRiskOfFakeLocation = detectRiskOfFakeLocation
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
        Self.logger.info("AMapLocationService startUpdatingLocation manager: \(String(describing: locationManager.description)) delegate: \(String(describing: locationManager.delegate?.description))")
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        Self.logger.info("AMapLocationService stopUpdatingLocation")
    }
}

extension AMapLocationService: AMapLocationManagerDelegate {

    func amapLocationManager(_ manager: AMapLocationManager!,
                             locationManagerDidChangeAuthorization locationManager: CLLocationManager!) {
        Self.logger.info("AMapLocationService received locationManagerDidChangeAuthorization")
        delegate?.locationService(self, locationManagerDidChangeAuthorization: locationManager)
    }

    func amapLocationManager(_ manager: AMapLocationManager!, didUpdate location: CLLocation!) {
        guard let location = location else {
            Self.logger.error("AMapLocationService received update location: nil")
            return
        }
        /// 是否在中国大陆/港/澳地区
        /// 高德地图在中国大陆/港/澳地区返回gcj02坐标系，在海外返回wjs84坐标系
        let isInternal = AMapLocationDataAvailableForCoordinate(location.coordinate)
        let locationSystem: LocationFrameType = isInternal ? .gcj02 : .wjs84
        let larkLocation = LarkLocation(location: location,
                                        locationType: locationSystem,
                                        serviceType: .aMap,
                                        time: Date(),
                                        authorizationAccuracy: shareLocationAuth().authorizationAccuracy())
        Self.logger.info("AMapLocationService received update location \(location), transform larkLocation: \(larkLocation)")
        delegate?.locationService(self, didUpdate: [larkLocation])
    }

    func amapLocationManager(_ manager: AMapLocationManager!, didFailWithError error: Error!) {
        Self.logger.info("AMapLocationService received error: \(String(describing: error))")
        delegate?.locationService(self, didFailWithError: error)
    }
}
#endif
