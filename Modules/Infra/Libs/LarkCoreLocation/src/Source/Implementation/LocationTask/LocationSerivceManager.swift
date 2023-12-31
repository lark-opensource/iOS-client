//
//  LocationTaskManager.swift
//  LarkCoreLocation
//
//  Created by zhangxudong on 3/29/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import CoreLocation
import LKCommonsLogging
import LarkSetting

/// 定位服务 观察者
protocol LocationServiceObserver: AnyObject {
    var desiredAccuracy: CLLocationAccuracy { get }
    var observableID: AnyHashable { get }
    func locationDidUpdate(location: LarkLocation, locations: [LarkLocation])
    func locationDidFailed(error: LocationError)
}
/// 定位服务被观察者
protocol LocationServiceObservable {
    /// 目前为止时间上最新&精度最好的定位
    var currentBestLocation: LarkLocation? { get }
    var locationService: LocationService { get }
    init(locationService: LocationService)
    func subscribe(observer: LocationServiceObserver)
    func unsubscribe(observer: LocationServiceObserver)
}
/// locationTask对LocationServiceObserver的默认实现
extension LocationTask where Self: LocationServiceObserver {
    var desiredAccuracy: CLLocationAccuracy { request.desiredAccuracy }
    var observableID: AnyHashable { taskID }
}

/// 管理定位任务 为定位任务提供: 共享定位服务, 定位服务回调转发, 定位服务管理，定位缓存处理
final class LocationServiceManager: LocationServiceObservable,
                                    LocationTaskSetting {
    private static let logger = Logger.log(LocationServiceManager.self, category: "LarkCoreLocation")
    /// 定位服务
    private(set) var locationService: LocationService
    /// 观察者集合
    private var observerMap: [AnyHashable: () -> LocationServiceObserver?] = [:]

    /// 目前为止精度最好的定位
    var currentBestLocation: LarkLocation? {
        Self.innerCurrentBestLocation
    }

    private static var innerCurrentBestLocation: LarkLocation? {
        didSet {
            Self.logger.info("currentBestLocation did update old: \(oldValue), new:(\(innerCurrentBestLocation))")
        }
    }

    required init(locationService: LocationService) {
        self.locationService = locationService
        self.locationService.delegate = self
        Self.logger.info("LocationServiceManager init")
    }
    /// 订阅定位服务
    func subscribe(observer: LocationServiceObserver) {
        observerMap[observer.observableID] = { [weak observer] in
            return observer
        }
        startOrStopServiceUpdateIfNeeded()
    }
    /// 取消订阅定位服务
    func unsubscribe(observer: LocationServiceObserver) {
        if observerMap[observer.observableID]?() == nil {
            return
        }
        observerMap.removeValue(forKey: observer.observableID)
        startOrStopServiceUpdateIfNeeded()
    }
    /// 根据观察者集合的真实数据来决定 定位服务是否开启
    private func startOrStopServiceUpdateIfNeeded() {
        if let minDesiredAccuracy = observerMap.values.compactMap({ $0()?.desiredAccuracy }).min() {
            Self.logger.info("LocationServiceManager startUpdatingLocation current DesiredAccuracy: \(minDesiredAccuracy)")
            locationService.desiredAccuracy = minDesiredAccuracy
            locationService.startUpdatingLocation()
        } else {
            Self.logger.info("LocationServiceManager stopUpdatingLocation")
            locationService.stopUpdatingLocation()
        }
    }
}

extension LocationServiceManager: LocationServiceDelegate {
    /**
     *  @brief 当定位发生错误时，会调用代理的此方法。
     *  @param manager 定位 LocationService 类。
     *  @param error 返回的错误，参考 CLError 。
     */
    func locationService(_ manager: LocationService, didFailWithError error: Error) {
        let locationError = LocationError.crateFrom(error: error)
        Self.logger.error("LocationServiceManager received locationService serverType:\(manager.serviceType.rawValue) error: \(error) transform LocationError:\(locationError)")
        self.observerMap.forEach {
            $0.value()?.locationDidFailed(error: locationError)
        }

    }
    /**
     *  @brief 连续定位回调函数.
     *  @param manager 定位 LocationService 类。
     *  @param location 定位结果。
     */
    func locationService(_ manager: LocationService, didUpdate locations: [LarkLocation]) {
        guard let location = locations.last else {
            Self.logger.error("locationService didUpdate locations is empty")
            return
        }
        Self.logger.info("LocationServiceManager received locationService serverType:\(manager.serviceType.rawValue) location: \(location)")
        // location的时间戳超过最大缓存时间则不再使用
        if Int(Date().timeIntervalSince1970 - location.location.timestamp.timeIntervalSince1970) <= self.maxLocationCacheTime {
            // 更新超过最大缓存时间内最新最好的定位
            Self.updateCurrentBestLocation(location)
        } else {
            Self.logger.warn("LocationServiceManager locationService serverType:\(manager.serviceType.rawValue) location: \(location) timeout, maxLocationCacheTime:\(maxLocationCacheTime)")
        }

        observerMap.forEach {
            $0.value()?.locationDidUpdate(location: location, locations: locations)
        }
    }
    /**
     *  @brief 定位权限状态改变时回调函数。
     *  @param manager 定位 LocationService 类。
     *  @param locationManager 定位CLLocationManager类，
     *  可通过locationManager.authorizationStatus获取定位权限，
     *  通过locationManager.accuracyAuthorization获取定位精度权限
     */
    func locationService(_ manager: LocationService,
                         locationManagerDidChangeAuthorization locationManager: CLLocationManager) {

    }

}
extension LocationServiceManager {
    /// 是否使用新版位置更新算法
    public static var isUseNewUpdateAlgorithm: Bool {
        return (locationTaskConfig["isUseNewUpdateLocationAlgorithm"] as? Bool) ?? false
    }
    /// 位置更新最长时长
    public static var updateCurrentLocationTimeout: TimeInterval {
        return (locationTaskConfig["updateCurrentLocationTimeout"] as? TimeInterval)  ?? 3.0
    }

    private static var locationTaskConfig: [String: Any] {
        do {
            let config = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "lark_core_location_task_config")) //Global
            return config
        } catch {
            return [:]
        }
    }

    private static func oldUpdateCurrentBestLocation(_ newLarkLocation: LarkLocation) {
        guard let currentBestLocation = innerCurrentBestLocation else {
            innerCurrentBestLocation = newLarkLocation
            return
        }
        // 超过5秒没有修改,且新定位是更新的点直接更新
        if -currentBestLocation.time.timeIntervalSinceNow > 5,
            newLarkLocation.location.timestamp > currentBestLocation.location.timestamp {
            innerCurrentBestLocation = newLarkLocation
            return
        }
        /// 当精度降低时
        if newLarkLocation.location.horizontalAccuracy > currentBestLocation.location.horizontalAccuracy {
            /// 如果新定位点还在原定位点的有效范围之内 则不更新
            let distance = currentBestLocation.location.distance(from: newLarkLocation.location)
            if distance < currentBestLocation.location.horizontalAccuracy {
                return
            }
        }
        innerCurrentBestLocation = newLarkLocation
    }

    private static func newUpdateCurrentBestLocation(_ newLocation: LarkLocation) {
        guard let currentBestLocation = Self.innerCurrentBestLocation else {
            self.innerCurrentBestLocation = newLocation
            return
        }
        let newTimestamp = newLocation.location.timestamp.timeIntervalSince1970
        let oldTimestamp = currentBestLocation.location.timestamp.timeIntervalSince1970

        let newAccuracy = newLocation.location.horizontalAccuracy
        let oldAccuracy = currentBestLocation.location.horizontalAccuracy

        /// newLocation 时间上更新
        if newTimestamp >= oldTimestamp,
           (newAccuracy <= oldAccuracy || newTimestamp - oldTimestamp > updateCurrentLocationTimeout) {
            self.innerCurrentBestLocation = newLocation
        }
    }

    static func updateCurrentBestLocation(_ newLarkLocation: LarkLocation) {
        Self.logger.info("updateCurrentBestLocation start! newLocation: \(newLarkLocation), currentBestLocation: \(Self.innerCurrentBestLocation), isUseNewUpdateAlgorithm: \(Self.isUseNewUpdateAlgorithm)")
        if Self.isUseNewUpdateAlgorithm {
            newUpdateCurrentBestLocation(newLarkLocation)
        } else {
            oldUpdateCurrentBestLocation(newLarkLocation)
        }
        Self.logger.info("updateCurrentBestLocation done! currentBestLocation: \(Self.innerCurrentBestLocation)")
    }
}
