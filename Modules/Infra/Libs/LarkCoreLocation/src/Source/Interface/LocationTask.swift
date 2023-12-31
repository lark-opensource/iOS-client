//
//  LocationTask.swift
//  LarkCoreLocation
//
//  Created by zhangxudong on 3/29/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import CoreLocation
import LarkSensitivityControl
/// 定位任务结果
public typealias LocationTaskResult = Swift.Result<LarkLocation, LocationError>
/// PSDA管控Token
public typealias PSDAToken = LarkSensitivityControl.Token

/// 通用的定位请求
public protocol LocationRequest {
    /// 期望的精度 具体参考 CLLocationAccuracy
    var desiredAccuracy: CLLocationAccuracy { get }
    /// 期望定位服务类型
    var desiredServiceType: LocationServiceType? { get }
    /// 埋点数据
    var monitorCategoryData: [String: Any]? { get }
}
/// 定位任务
public protocol LocationTask: AnyObject {
    /// 定位请求
    var request: LocationRequest { get }
    /// 定位ID
    var taskID: AnyHashable { get }
    /// 是否在定位
    var isLocating: Bool { get }
    /// 定位状态改变
    var locationStateDidChangedCallback: ((Bool) -> Void)? { get set }
}

/// 单次定位请求
public struct SingleLocationRequest: LocationRequest {
    /// 期望的精度
    public let desiredAccuracy: CLLocationAccuracy
    /// 定位超时时间，单位秒。 kCLLocationAccuracyBest 下建议10s kCLLocationAccuracyHundredMeters 建议3s
    public let timeout: TimeInterval
    /// 定位缓存超时时间，单位秒；每次定位缓存当前定位数据，并记下时间戳，当下次调用在 cacheTimeout 之内时，返回缓存数据。如果 cacheTimeout 小于 0 或大于 60s，则不使用缓存
    public let cacheTimeout: TimeInterval
    /// 期望使用的服务类型 如果不传则依sdk为准
    public let desiredServiceType: LocationServiceType?
    public let monitorCategoryData: [String: Any]?
    public init(desiredAccuracy: CLLocationAccuracy,
                desiredServiceType: LocationServiceType? = nil,
                timeout: TimeInterval,
                cacheTimeout: TimeInterval,
                monitorCategoryData: [String: Any]? = nil) {
        self.desiredAccuracy = desiredAccuracy
        self.desiredServiceType = desiredServiceType
        self.timeout = timeout
        self.cacheTimeout = (0...60).contains(cacheTimeout) ? cacheTimeout : 0
        self.monitorCategoryData = monitorCategoryData
    }
}

/// 单次定位结果Callback
public typealias SingleLocationTaskComplete = ((SingleLocationTask, LocationTaskResult) -> Void)
/// 单次定位收到 位置更新 callback
public typealias SingleLocationTaskUpdateCallback = ((SingleLocationTask, LarkLocation) -> Void)
/// 单次定位任务
public protocol SingleLocationTask: LocationTask {
    var locationRequest: SingleLocationRequest { get }
    var locationDidUpdateCallback: SingleLocationTaskUpdateCallback? { get set }
    var locationCompleteCallback: SingleLocationTaskComplete? { get set }

    /// 接入PSDA  开启定位 throws 参考 LarkLocationAuthorizationError,如果checkToken失败参考 LocationError
    func resume(forToken: PSDAToken) throws
    /// 取消定位
    func cancel()
}

public extension SingleLocationTask {
    /// 统一对外的request
    var request: LocationRequest { locationRequest }
}

/// 持续定位 位置更新 callback
public typealias ContinueLocationTaskUpdateCallback = ((ContinueLocationTask, LarkLocation, [LarkLocation]) -> Void)
/// 持续定位遇到错误 callback
public typealias ContinueLocationDidFailedCallback = ((ContinueLocationTask, LocationError) -> Void)
// 持续定位task
public protocol ContinueLocationTask: LocationTask {
    /// 位置更新回调
    var locationDidUpdateCallback: ContinueLocationTaskUpdateCallback? { get set }
    /// 定位遇到错误回调
    var locationDidFailedCallback: ContinueLocationDidFailedCallback? { get set }
    /// 停止位置更新
    func stopLocationUpdate()
    /// 接入PSDA  开始位置更新 throws 参考 LarkLocationAuthorizationError
    func startLocationUpdate(forToken: PSDAToken) throws
}
/// 持续定位请求
public struct ContinueLocationRequest: LocationRequest {
    /// 期望精度 可以传入任何double类型  具体参考 CLLocationAccuracy 
    public let desiredAccuracy: CLLocationAccuracy
    /// 期望定位服务类型 如果不传则依SDK为准
    public let desiredServiceType: LocationServiceType?

    public let monitorCategoryData: [String: Any]?

    public init(desiredAccuracy: CLLocationAccuracy,
                desiredServiceType: LocationServiceType? = nil,
                monitorCategoryData: [String: Any]? = nil) {
        self.desiredAccuracy = desiredAccuracy
        self.desiredServiceType = desiredServiceType
        self.monitorCategoryData = monitorCategoryData
    }
}
