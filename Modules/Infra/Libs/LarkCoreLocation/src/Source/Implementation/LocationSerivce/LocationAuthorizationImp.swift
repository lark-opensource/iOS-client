//
//  LocationAuth.swift
//  LarkCoreLocation
//
//  Created by zhangxudong on 3/29/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import CoreLocation
import LKCommonsLogging
import Swinject
import LarkPrivacySetting
import LarkSensitivityControl
import LarkSetting

func shareLocationAuth() -> LocationAuthorization {
    return LocationAuthorizationImp.shared
}

/// 定位权限相关操作
final class LocationAuthorizationImp: NSObject,
                                      LocationAuthorization,
                                      CLLocationManagerDelegate,
                                      LocationTaskSetting {

    static let shared = LocationAuthorizationImp()
    private static let logger = Logger.log(LocationAuthorizationImp.self, category: "LarkCoreLocation")
    private var requestWhenInUseAuthorizationCallBacks: [LocationAuthorizationCallback] = []
    private lazy var locationManager: CLLocationManager = {
       let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()

    func locationServicesEnabled() -> Bool {
        Self.logger.info("LocationAuthorizationImp request locationServicesEnabled")
        let monitor = LocationAuthorizationMonitor()
        monitor.start()
        if servicesEnabledBackground {
            // 处理进程间卡死
            // CLLocationManager.locationServicesEnabled() 有进程间卡顿造成 watchdog 强杀APP的情况
            // 等待getServicesEnabledWaitTimeout毫秒(settings下发) 超时则认为失败
            var isEnabled = false
            let semaphore = DispatchSemaphore(value: 1)
            semaphore.wait()
            DispatchQueue.global().async {
                isEnabled = CLLocationManager.locationServicesEnabled()
                semaphore.signal()
            }
            let timeoutResult = semaphore.wait(timeout: .now() + .milliseconds(getServicesEnabledWaitTimeout))
            switch timeoutResult {
            case .success:
                semaphore.signal()
                monitor.end(isEnabled: isEnabled, isWaitTimeout: false)
                Self.logger.info("LocationAuthorizationImp locationServicesEnabled result: \(isEnabled)")
            case .timedOut:
                monitor.end(isEnabled: isEnabled, isWaitTimeout: true)
                Self.logger.error("LocationAuthorizationImp request locationServicesEnabled timeout")
            }
            Self.logger.info("LocationAuthorizationImp locationServicesEnabled status is: \(isEnabled)")
            return isEnabled

        } else {
            let isEnabled = CLLocationManager.locationServicesEnabled()
            monitor.end(isEnabled: isEnabled)
            Self.logger.info("LocationAuthorizationImp locationServicesEnabled status is: \(isEnabled)")
            return isEnabled
        }
    }

    func authorizationStatus() -> CLAuthorizationStatus {
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = locationManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        Self.logger.info("LocationAuthorizationImp authorizationStatus: \(status)")
        return status
    }

//    func requestWhenInUseAuthorization(complete: @escaping LocationAuthorizationCallback) {
//        Self.logger.info("LocationAuthorizationImp requestWhenInUseAuthorization")
//        executeOnMainThread {
//            self.requestWhenInUseAuthorizationCallBacks.append(complete)
//            let error = self.checkWhenInUseAuthorization()
//            if error == .notDetermined {
//                self.locationManager.requestWhenInUseAuthorization()
//                return
//            }
//            self.notifyWhenInUseAuthorization(error: error)
//        }
//    }

    func requestWhenInUseAuthorization(forToken: Token, complete: @escaping LocationAuthorizationCallback) {
        Self.logger.info("LocationAuthorizationImp requestWhenInUseAuthorization PSDA token \(forToken.identifier) \(forToken.type)")
        executeOnMainThread {
            self.requestWhenInUseAuthorizationCallBacks.append(complete)
            let error = self.checkWhenInUseAuthorization()
            if error == .notDetermined {
                self.useSystemRequestLocationAuthorization(token: forToken, manager: self.locationManager)
                return
            }
            self.notifyWhenInUseAuthorization(error: error)
        }
    }

    private func useSystemRequestLocationAuthorization(token: Token, manager: CLLocationManager) {
        Self.logger.info("requestLocationAuthorization token \(token.identifier) \(token.type)")
        do {
            try LocationEntry.requestWhenInUseAuthorization(forToken: token, manager: manager)
        } catch let error as CheckError {
            Self.logger.info("locationEntry checkError \(error.description)")
            notifyWhenInUseAuthorization(error: .psdaRestricted)
        } catch {
            Self.logger.info("locationEntry otherError")
            notifyWhenInUseAuthorization(error: .psdaRestricted)
        }
    }

    func isAdminAllowGPS() -> Bool {
        let result = LarkLocationAuthority.checkAuthority()
        Self.logger.info("LocationAuthorizationImp isAdminAllowGPS result:\(result)")
        return result
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        /// CLLocationManager 的 delegate 被赋值的时候，会有一次回调，这次回调的值可能是notDetermined，
        /// FG "core.location.forbid_return_notdetermined" 默认常关闭。
        Self.logger.error("LocationAuthorizationImp did change authorization status: \(status)")
        if !FeatureGatingManager.realTimeManager.featureGatingValue(with: "core.location.forbid_return_notdetermined"), //Global 和用户数据无关，按照版本来控制fg的value
            status == .notDetermined {
            Self.logger.error("LocationAuthorizationImp did change authorization notDetermined early return")
            return
        }
        let error = checkWhenInUseAuthorization()
        if let error = error {
            if error == .notDetermined {
                Self.logger.error("LocationAuthorizationImp received error should not be notDetermined")
            }
            Self.logger.info("LocationAuthorizationImp received requestWhenInUseAuthorization failed:\(error)")
        } else {
            Self.logger.info("LocationAuthorizationImp received requestWhenInUseAuthorization success")
        }
        notifyWhenInUseAuthorization(error: error)
    }

    private func notifyWhenInUseAuthorization(error: LocationAuthorizationError?) {
        Self.logger.info("LocationAuthorizationImp notifyWhenInUseAuthorization error: \(String(describing: error))")
        requestWhenInUseAuthorizationCallBacks.forEach { $0(error) }
        requestWhenInUseAuthorizationCallBacks.removeAll()
    }

    /// 精度级别
    func authorizationAccuracy() -> AuthorizationAccuracy {
        if #available(iOS 14.0, *) {
            switch locationManager.accuracyAuthorization {
            case .fullAccuracy:
                return .full
            case .reducedAccuracy:
                return .reduced
            @unknown default:
                return .unknown
            }
        }
        return .unknown
    }
}

extension LocationAuthorizationError {
    init?(authorizationStatus: CLAuthorizationStatus) {
        if authorizationStatus == .denied {
            self = .denied
            return
        }
        if authorizationStatus == .restricted {
            self = .restricted
            return
        }
        return nil
    }
}
