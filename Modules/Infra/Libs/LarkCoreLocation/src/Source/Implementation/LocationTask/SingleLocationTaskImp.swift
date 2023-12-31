//
//  SingleLocationTask.swift
//  LarkCoreLocation
//
//  Created by zhangxudong on 3/29/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import CoreLocation
import RxSwift
import RxCocoa
import LKCommonsLogging
import LarkSetting
import LarkSensitivityControl
/// 单次定位任务
final class SingleLocationTaskImp: SingleLocationTask,
                                   LocationTaskSetting {
    private static let logger = Logger.log(SingleLocationTask.self, category: "LarkCoreLocation")
    let locationRequest: SingleLocationRequest
    let taskID: AnyHashable = UUID()
    private(set) var isLocating: Bool = false {
        didSet {
            locationStateDidChangedCallback?(isLocating )
        }
    }
    var locationStateDidChangedCallback: ((Bool) -> Void)?
    var locationCompleteCallback: SingleLocationTaskComplete?
    var locationDidUpdateCallback: SingleLocationTaskUpdateCallback?
    private var occurredError: LocationError?
    private let locationServerObservable: LocationServiceObservable
    private var timeoutTimer: Timer?
    private lazy var monitor: SingleLocationTaskMonitor = SingleLocationTaskMonitor(request: locationRequest)

    private lazy var tracker: SingleLocationTeaTracker = SingleLocationTeaTracker(serviceType: locationServerObservable.locationService.serviceType)
    /// 单次定位在规定的时间内（timeout）尝试获取定位精度最符合用户 调用方要求的位置数据
    /// 如果在timeout时间内获取不到，则会给一个最接近符合精度的数据。
    /// backupLocation 是目前最好的精度数据
    init(request: SingleLocationRequest,
         locationServerObservable: LocationServiceObservable) {
        self.locationRequest = request
        self.locationServerObservable = locationServerObservable
        Self.logger.info("taskID: \(taskID) SingleLocationTask init request:\(request)")
    }
    /// 重新开始任务
    func resume() throws {
        try resumeTask()
    }

    /// 重新开始任务
    /// - Parameter forToken: 敏感API管控SDK所属Token
    func resume(forToken: PSDAToken) throws {
        Self.logger.info("resume PSDA token \(forToken.identifier) \(forToken.type)")
        do {
            let context = Context(sdkName: "LarkCoreLocation", methodName: "resume")
            try SensitivityManager.shared.checkToken(forToken, type: .location, context: context)
        } catch let error as CheckError {
            Self.logger.info("resume failure checkError \(error.description)")
            throw LocationAuthorizationError.psdaRestricted
        } catch {
            Self.logger.info("resume failure otherError")
            throw LocationAuthorizationError.psdaRestricted
        }
        try resumeTask()
    }

    func resumeTask() throws {
        monitor.start(serviceType: locationServerObservable.locationService.serviceType, isUseNewAlgorithm: isUseNewUpdateAlgorithm)
        if let error = shareLocationAuth().checkWhenInUseAuthorization() {
            Self.logger.error("taskID: \(self.taskID) SingleLocationTask resume error:\(error)")
            monitor.startFailed(error: error)
            throw error
        }
        executeOnMainThread {
            self.cleanPreTask()
            self.startTask()
        }
        Self.logger.info("taskID: \(taskID) SingleLocationTask start location, authorizationAccuracy: \(shareLocationAuth().authorizationAccuracy())")
    }

    private func startTask() {
        // 查看是否有合适的缓存
        if var location = self.getAvailableCache() {
            Self.logger.info("taskID: \(taskID) SingleLocationTask getAvailableCache location:\(location)")
            location.sourceType = .cache
            tracker.start(dataSource: "cache")
            completeLocationTask(result: .success(location))
            return
        }
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(self.locationRequest.timeout),
                                           repeats: false,
                                           block: { [weak self] _ in
            self?.locationTaskTimeout()
        })
        tracker.start(dataSource: "sdk")
        startSubscribeLocation()
    }

    /// 取消结束任务
    func cancel() {
        executeOnMainThread {
            self.cleanPreTask()
            self.stopSubscribeLocation()
        }
        Self.logger.info("taskID: \(taskID) SingleLocationTask cancel")
    }

    /// 定位任务超时
    private func locationTaskTimeout() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil

        if var backupLocation = currentLocation {
            Self.logger.info("taskID: \(taskID) SingleLocationTask locationTaskTimeout use backupLocation \(backupLocation)")
            backupLocation.sourceType = .backup
            completeLocationTask(result: .success(backupLocation))
            return
        }

        let error = occurredError ?? .timeout
        Self.logger.error("taskID: \(taskID) SingleLocationTask locationTaskTimeout! can not use backupLocation! error: \(error)")
        completeLocationTask(result: .failure(LocationError.timeout))
    }
    /// 获取合适的缓存数据
    private func getAvailableCache() -> LarkLocation? {
        return locationServerObservable.getLocationCache(for: locationRequest.desiredAccuracy,
                                         cacheTimeout: locationRequest.cacheTimeout)
    }
    /// 清除上一次定位数据
    private func cleanPreTask() {
        Self.logger.info("taskID: \(taskID) SingleLocationTask stoped")
        occurredError = nil
        currentLocation = nil
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }

    private func stopSubscribeLocation() {
        locationServerObservable.unsubscribe(observer: self)
        isLocating = false
        Self.logger.info("taskID: \(taskID) SingleLocationTask stopSubscribeLocation")
    }

    private func startSubscribeLocation() {
        locationServerObservable.subscribe(observer: self)
        isLocating = true
        Self.logger.info("taskID: \(taskID) SingleLocationTask startSubscribeLocation")
    }

    /// 任务结束
    private func completeLocationTask(result: LocationTaskResult) {
        locationCompleteCallback?(self, result)
        cleanPreTask()
        stopSubscribeLocation()
        let msg = "taskID: \(taskID) SingleLocationTask completeLocationTask result:\(result)"
        switch result {
        case .success(let location):
            Self.logger.info(msg)
            tracker.success(location: location)
            monitor.success(location: location)
        case .failure(let error):
            Self.logger.error(msg)
            tracker.failed(error: error)
            monitor.failed(error: error)
        }
    }

    deinit {
        Self.logger.info("taskID: \(taskID) SingleLocationTask deinit")
        cleanPreTask()
        stopSubscribeLocation()

    }
    private  var currentLocation: LarkLocation?

    /// 老的更新定位方法 更新定位并没有对比时效性和精确度
    private func oldUpdateCurrentLocation(_ newLocation: LarkLocation) {
        guard let currentLocation = currentLocation else {
            self.currentLocation = newLocation
            return
        }
        /// 精度降低时
        if newLocation.location.horizontalAccuracy > currentLocation.location.horizontalAccuracy {
            /// 如果新定位点还在原定位点的有效范围之内 则不更新
            let distance = currentLocation.location.distance(from: newLocation.location)
            if distance < currentLocation.location.horizontalAccuracy {
                return
            }
        }
        self.currentLocation = newLocation
    }

    /// 新的更新定位方法 使用最新最好的定位
    private func newUpdateCurrentLocation(_ newLocation: LarkLocation) {
        guard let currentLocation = currentLocation else {
            self.currentLocation = newLocation
            return
        }
        /*
         定位的更新有两个维度
         1. timestamp:时间戳 越大越好
         2. accuracy: 精确度 越小越好
         对比两个维度由以下几种情况
         1. new.timestamp >= old.timestamp && new.accuracy > old.accuracy：  定位是最新，精确度不是更好的      若时差阈值则使用
         2. new.timestamp >= old.timestamp && new.accuracy <= old.accuracy： 定位是最新的，精确度更好          最好的结果 立即使用
         3. new.timestamp < old.timestamp && new.accuracy > old.accuracy：   定位不是最新的，精确度不是更好的   最差的结果，放弃使用
         4. new.timestamp < old.timestamp && new.accuracy <= old.accuracy：  定位不是最新的，精确度是更好的     若时差在阈值内 使用 ？
         对于 4 我的结论是最好不用，从定位的oncall 来看，除了 定位SDK的问题大部分都是用到时效性差的定位。所以对4 不再使用
         那么上面的逻辑可以如下表示
         */
        let newTimestamp = newLocation.location.timestamp.timeIntervalSince1970
        let oldTimestamp = currentLocation.location.timestamp.timeIntervalSince1970

        let newAccuracy = newLocation.location.horizontalAccuracy
        let oldAccuracy = currentLocation.location.horizontalAccuracy

        /// newLocation 时间上更新
        if newTimestamp >= oldTimestamp,
           (newAccuracy <= oldAccuracy || newTimestamp - oldTimestamp > updateCurrentLocationTimeout) {
            self.currentLocation = newLocation
        }
    }

    private func updateCurrentLocation(_ newLocation: LarkLocation) {
        Self.logger.info("taskID: \(taskID) SingleLocationTask updateCurrentLocation start! isUseNewUpdateAlgorithm: \(isUseNewUpdateAlgorithm), newLocation: \(newLocation), currentLocation: \(currentLocation)")
        if isUseNewUpdateAlgorithm {
            newUpdateCurrentLocation(newLocation)
        } else {
            oldUpdateCurrentLocation(newLocation)
        }
        Self.logger.info("taskID: \(taskID) SingleLocationTask updateCurrentLocation done! currentLocation: \(currentLocation)")
    }

    private func isAccuracyAvailable(for larkLocation: LarkLocation) -> Bool {
        let location = larkLocation.location
        return location.horizontalAccuracy <= request.desiredAccuracy &&
        location.verticalAccuracy <= request.desiredAccuracy
    }

}

extension SingleLocationTaskImp: LocationServiceObserver {

    func locationDidUpdate(location: LarkLocation, locations: [LarkLocation]) {
        Self.logger.info("taskID: \(taskID) SingleLocationTask received location update location:\(location)")
        locationDidUpdateCallback?(self, location)
        // https://bytedance.feishu.cn/docs/doccndL10Itf18CztcayNN2fMnh#
        // 超过maxLocationCacheTime的数据不要
        if Int(Date().timeIntervalSince1970 - location.location.timestamp.timeIntervalSince1970) > maxLocationCacheTime {
            Self.logger.warn("taskID: \(taskID) SingleLocationTask received location:\(location) SDK cache timeout")
        } else {
            // location 符合要求的精度则 回调成功并结束task
            // 否则 更新 backup
            updateCurrentLocation(location)
            if let larkLocation = self.currentLocation,
               isAccuracyAvailable(for: larkLocation) {
                completeLocationTask(result: .success(larkLocation))
            }
        }
    }

    func locationDidFailed(error: LocationError) {
        Self.logger.error("taskID: \(taskID) SingleLocationTask received location error: \(error)")
        self.occurredError = error
    }
}

private extension LocationError {
    static var timeout: LocationError {
        return LocationError(rawError: nil, errorCode: .timeout, message: "location timeout")
    }
}

extension LocationServiceObservable {
    /// 根据预期的精度与最大缓存时间来获取缓存位置
    /// 是否使用缓存的条件是
    /// 1. 缓存的时间不超过 cacheTimeout
    /// 2. location的精度不高于 desiredAccuracy
    func getLocationCache(for desiredAccuracy: CLLocationAccuracy, cacheTimeout: TimeInterval) -> LarkLocation? {
        guard cacheTimeout > 0,
             let location = currentBestLocation,
              -location.time.timeIntervalSinceNow <= cacheTimeout,
              location.location.verticalAccuracy <= desiredAccuracy,
              location.location.horizontalAccuracy <= desiredAccuracy else {
                  return nil
              }
        return location

    }
}
