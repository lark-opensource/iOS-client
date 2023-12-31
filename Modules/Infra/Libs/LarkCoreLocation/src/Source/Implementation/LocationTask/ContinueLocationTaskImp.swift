//
//  ContinueLocationTask.swift
//  LarkCoreLocation
//
//  Created by zhangxudong on 3/29/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import CoreLocation
import LKCommonsLogging
import LarkSensitivityControl
/// 持续定位任务
final class ContinueLocationTaskImp: ContinueLocationTask {
    private static let logger = Logger.log(ContinueLocationTask.self, category: "LarkCoreLocation")
    var request: LocationRequest
    let taskID: AnyHashable = UUID()
    var locationDidUpdateCallback: ContinueLocationTaskUpdateCallback?
    var locationDidFailedCallback: ContinueLocationDidFailedCallback?
    /// location server
    private let locationServerObservable: LocationServiceObservable
    private(set) var isLocating: Bool = false {
        didSet {
            locationStateDidChangedCallback?(isLocating )
        }
    }
    var locationStateDidChangedCallback: ((Bool) -> Void)?
    private lazy var monitor: ContinueLocationTaskMonitor =
    ContinueLocationTaskMonitor(request: request,
                              serviceType: locationServerObservable.locationService.serviceType)

    init(request: LocationRequest, locationServerObservable: LocationServiceObservable) {
        self.locationServerObservable = locationServerObservable
        self.request = request
        Self.logger.info("taskID: \(taskID) ContinueLocationTask init request: \(request)")
    }

    /// 用户操作关闭用户更新
    func stopLocationUpdate() {
        Self.logger.info("taskID: \(taskID) ContinueLocationTask stopLocationUpdate")
        stopSubscribeLocation()
    }

    // 用户操作开启位置更新
    func startLocationUpdate() throws {
        try startLocationUpdateTask()
    }

    /// 用户操作开启位置更新
    /// - Parameter forToken: 敏感API管控SDK所属Token
    func startLocationUpdate(forToken: PSDAToken) throws {
        Self.logger.info("startLocationUpdate PSDA token \(forToken.identifier) \(forToken.type)")
        do {
            let context = Context(sdkName: "LarkCoreLocation", methodName: "startLocationUpdate")
            try SensitivityManager.shared.checkToken(forToken, type: .location, context: context)
        } catch let error as CheckError {
            Self.logger.info("startLocationUpdate failure checkError \(error.description)")
            throw LocationAuthorizationError.psdaRestricted
        } catch {
            Self.logger.info("startLocationUpdate failure otherError")
            throw LocationAuthorizationError.psdaRestricted
        }
        try startLocationUpdateTask()
    }

    func startLocationUpdateTask() throws {
        if let error = shareLocationAuth().checkWhenInUseAuthorization() {
            Self.logger.info("taskID: \(self.taskID) ContinueLocationTask startLocationUpdate failed: \(error)")
            monitor.startFailed(error: error)
            throw error
        }
        startSubscribeLocation()
        monitor.startSuccess()
    }

    /// 关闭位置监听
    private func stopSubscribeLocation() {
        executeOnMainThread {
            self.isLocating = false
            self.locationServerObservable.unsubscribe(observer: self)
        }
        Self.logger.info("taskID: \(self.taskID) ContinueLocationTask stopSubscribeLocation")
        monitor.stopSuccess()
    }

    /// 开启位置监听
    private func startSubscribeLocation() {
        executeOnMainThread {
            if !self.isLocating {
                self.isLocating = true
                self.locationServerObservable.subscribe(observer: self)
            }
        }
        Self.logger.info("taskID: \(self.taskID) ContinueLocationTask startSubscribeLocation, authorizationAccuracy: \(shareLocationAuth().authorizationAccuracy())")
    }

    deinit {
        Self.logger.info("taskID: \(taskID) ContinueLocationTask deinit")
        stopSubscribeLocation()
    }
}

extension ContinueLocationTaskImp: LocationServiceObserver {
    /// 位置开始更新
    func locationDidUpdate(location: LarkLocation, locations: [LarkLocation]) {
        Self.logger.info("taskID: \(taskID) ContinueLocationTask received Serviced  update location:\(location), locations: \(locations)")
        locationDidUpdateCallback?(self, location, locations)
    }
    /// 位置更新遇到了问题
    func locationDidFailed(error: LocationError) {
        Self.logger.error("taskID: \(taskID) ContinueLocationTask received Serviced locationDidFailed error:\(error)")
        locationDidFailedCallback?(self, error)
        monitor.failed(error: error)
    }
}
