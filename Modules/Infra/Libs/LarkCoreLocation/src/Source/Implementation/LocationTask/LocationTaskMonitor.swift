//
//  LocationTaskMonitor.swift
//  LarkCoreLocation
//
//  Created by zhangxudong on 5/14/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LKCommonsTracker
import Homeric
import ThreadSafeDataStructure
import AppReciableSDK
import CoreLocation
#if canImport(AMapLocationKit)
import AMapLocationKit
#endif
/// Monitor 的一些通用key
private enum MonitorEventKey: String {
    /// 开始时间
    case startTime
    /// 耗时
    case duration
}
/// LKCommonsTracker.Tracker 的简单封装
private final class Monitor {

    let eventName: String
    init(eventName: String) {
        self.eventName = eventName
    }
    private var _metricValues: SafeDictionary<String, Any> = [:] + .readWriteLock

    public var metricValues: [String: Any] {
        get { _metricValues.getImmutableCopy() }
        set { _metricValues.replaceInnerData(by: newValue) }
    }
    private var _categoryValues: SafeDictionary<String, Any> = [:] + .readWriteLock

    public var categoryValues: [String: Any] {
        get { _categoryValues.getImmutableCopy() }
        set { _categoryValues.replaceInnerData(by: newValue) }
    }
    private var _extraValues: SafeDictionary<String, Any> = [:] + .readWriteLock

    public var extraValues: [String: Any] {

        get { _extraValues.getImmutableCopy()  }
        set { _extraValues.replaceInnerData(by: newValue) }
    }

    private var _paramValues: SafeDictionary<String, Any> = [:] + .readWriteLock

    public var paramValues: [String: Any] {
        get { _paramValues.getImmutableCopy() }
        set { _paramValues.replaceInnerData(by: newValue) }
    }

    /// 添加一个自定义的 Key-Value，value 为值类型（可计算平均值）
    /// 重复设置相同key会覆盖
    @discardableResult
    public func addMetric(key: String, value: Any?) -> Monitor {
        if let value = value {
            metricValues[key] = value
        }
        return self
    }

    /// 添加一个自定义的 Key-Value，value
    /// 重复设置相同key会覆盖
    @discardableResult
    public func addCategory(key: String, value: Any?) -> Monitor {
        if let value = value {
            categoryValues[key] = value
        }
        return self
    }

    /// 添加一个Tag，可以添加多个Tag
    @discardableResult
    public func addExtra(key: String, value: Any?) -> Monitor {
        if let value = value {
            extraValues[key] = value
        }
        return self
    }

    /// 添加一个自定义的 Key-Value，value
    /// 重复设置相同key会覆盖
    @discardableResult
    public func addParam(key: String, value: Any?) -> Monitor {
        if let value = value {
            paramValues[key] = value
        }
        return self
    }

    @discardableResult
    public func success() -> Monitor {
        metricValues["result"] = "success"
        paramValues["result_status"] = "success"
        return self
    }

    @discardableResult
    public func failure() -> Monitor {
        metricValues["result"] = "failure"
        paramValues["result_status"] = "fail"
        return self
    }

    /// 记录一个时间点，在下一次时间点调用的时候会自动计算与首次 timing 的时间差值转换为 duration : (time1 - time0) 设置到打点数据集合中
    /// 如果对于同一个 key 设置多次 timing ，每次都会重新计算与首次 timing 的时间差值并覆盖上一次的计算结果
    @discardableResult
    public func timing() -> Monitor {
        if let startTime = extraValues[MonitorEventKey.startTime.rawValue] as? TimeInterval {
            let endTime = Date().timeIntervalSince1970 * 1000
            let duration = endTime - startTime
            return setDuration(duration)
        } else {
            return setStartTime(Date().timeIntervalSince1970 * 1000)
        }
    }

    /// 设置开始时间戳 单位：秒。 Date timeIntervalSince1970 的值需要 * 1000
    @discardableResult
    public func setStartTime(_ time: TimeInterval) -> Monitor {
        extraValues[MonitorEventKey.startTime.rawValue] = time
        return self
    }

    /// 时长以毫秒为 单位：秒。 Date timeIntervalSince1970 的值需要 * 1000
    @discardableResult
    public func setDuration(_ duration: TimeInterval) -> Monitor {
        extraValues[MonitorEventKey.duration.rawValue] = duration
        return self
    }

    /// 清空 metricValues categoryValues extraValues
    public func resetAllEvents() {
        metricValues = [:]
        categoryValues = [:]
        extraValues = [:]
    }

    /// 提交数据
    public func flushSlardar(fileName: String = #fileID,
                             functionName: String = #function,
                             line: Int = #line) {
        extraValues["flushLog"] = "file:\(fileName) line:\(line) function:\(functionName)"
        Tracker.post(SlardarEvent(name: eventName,
                                  metric: metricValues,
                                  category: categoryValues,
                                  extra: extraValues))
    }

    /// 提交数据 tea埋点
    public func flushTea(
        fileName: String = #fileID,
        functionName: String = #function,
        line: Int = #line) {
        extraValues["flushLog"] = "file:\(fileName) line:\(line) function:\(functionName)"
        Tracker.post(TeaEvent(eventName,
                              params: paramValues))
    }
}

/// 单次定位Tea埋点
final class SingleLocationTeaTracker {
    /// Tea埋点的字段是设计好的，所以不从monitorCategoryData中取值
    private let startMonitor: Monitor
    private let resultMonitor: Monitor
    private var startTime: CFTimeInterval
    private static var isFirst: Bool = true

    init(serviceType: LocationServiceType) {
        startMonitor = Monitor(eventName: Homeric.CORE_LOCATION_START_DEV)
            .addParam(key: "map_type", value: serviceType.mapType)

        resultMonitor = Monitor(eventName: Homeric.CORE_LOCATION_DEV)
            .addParam(key: "map_type", value: serviceType.mapType)
            .addAuthorizationAccuracy()
        startTime = CACurrentMediaTime()
    }

    func start(dataSource: String) {
        startTime = CACurrentMediaTime()
        let netStatus = AppReciableSDK.shared.getActualNetStatus(start: startTime, end: startTime)
        startMonitor.addParam(key: "net_status", value: String(netStatus))
        startMonitor.addParam(key: "is_first_location", value: SingleLocationTeaTracker.isFirst ? "1" : "0")
        startMonitor.addParam(key: "data_source", value: dataSource)
        startMonitor.addAuthorizationAccuracy()
        startMonitor.flushTea()
    }

    func failed(error: LocationError) {
        self.addResultParams()
        resultMonitor.addParam(key: "result_code", value: LocationError.getRawErrorCode(error: error.rawError))
        resultMonitor.failure()
        resultMonitor.flushTea()
        SingleLocationTeaTracker.isFirst = false
    }

    func success(location: LarkLocation) {
        self.addResultParams()
        /// 成功结果上报数据来源
        resultMonitor.addParam(key: "data_source", value: location.sourceType.sourceTeaValue)
        resultMonitor.success()
        resultMonitor.flushTea()
        SingleLocationTeaTracker.isFirst = false
    }

    /// 结果公用字段
    private func addResultParams() {
        let currentTime = CACurrentMediaTime()
        let timeCost = Int((currentTime - startTime) * 1000)
        let netStatus = AppReciableSDK.shared.getActualNetStatus(start: startTime, end: startTime)
        resultMonitor.addParam(key: "net_status", value: String(netStatus))
        resultMonitor.addParam(key: "is_first_location", value: SingleLocationTeaTracker.isFirst ? "1" : "0")
        resultMonitor.addAuthorizationAccuracy()
        resultMonitor.addParam(key: "sdk_cost", value: timeCost)
    }
}

/// 位置更新遇到的错误
struct LocationUpdateOccurredError {
    enum MetaType: String {
        /// CLError 一般为 Apple地图返回
        case clError
        /// 高德返回
        case amap
        /// 未知类型
        case unknown
    }

    init(error: Error, timestamp: Date = Date()) {
        self.timestamp = timestamp
        if let clError = error as? CLError {
            metaType = .clError
            code = clError.code.rawValue
            description = "\(clError)"
            return
        }
#if canImport(AMapLocationKit)
        if let nsError = error as? NSError, let errorCode = AMapLocationErrorCode(rawValue: nsError.code) {
            metaType = .amap
            code = errorCode.rawValue
            description = "\(nsError)"
            return
        }
#endif
        metaType = .unknown
        description = "\(error)"
        code = -1
    }

    let metaType: MetaType
    let code: Int
    let description: String
    let timestamp: Date

    var dictionary: [String: Any] {
        return ["metaType": metaType.rawValue,
                "code": code,
                "description": description,
                "timestamp": timestamp.timeIntervalSince1970 * 1000]
    }
}

/// 单次定位Task埋点
final class SingleLocationTaskMonitor {

    enum FailedReason: String {
        case error
        case timeout
    }
    private let monitor: Monitor
    private let request: SingleLocationRequest
    init(request: SingleLocationRequest) {
        self.request = request
        monitor = Monitor(eventName: Homeric.LARK_CORE_LOCATION_SINGLE_TASK)
    }

    /// 开启位置更新
    func start(serviceType: LocationServiceType, isUseNewAlgorithm: Bool) {
        monitor.resetAllEvents()
        monitor.addLocationRequest(request)
            .addAuthorizationAccuracy()
            .addCategory(key: "cacheTimeout", value: request.cacheTimeout)
            .addCategory(key: "serviceType", value: serviceType.rawValue)
            .addCategory(key: "cacheTimeout", value: request.cacheTimeout)
            .addCategory(key: "isUseNewAlgorithm", value: isUseNewAlgorithm)

        request.monitorCategoryData?.forEach {
            monitor.addCategory(key: $0.key, value: $0.value)
        }
        monitor.timing()
    }

    /// 开启持续定位失败
    func startFailed(error: LocationAuthorizationError) {
        monitor.addCategory(key: "startFailed", value: error.description)
        monitor.failure()
        monitor.flushSlardar()
    }

//    /// 定位过程中遇到错误
//    func locationUpdate(error: LocationError) {
//        let occurredErrorsKey = "occurredErrors"
//        guard var occurredErrors = monitor.categoryValues[occurredErrorsKey] as? [[String: Any]] else {
//            return
//        }
//        let errorDict = LocationUpdateOccurredError(error: error.rawError ?? error, timestamp: Date()).dictionary
//        occurredErrors.append(errorDict)
//        monitor.addCategory(key: occurredErrorsKey, value: errorDict)
//    }

    /// 定位结果失败
    func failed(error: LocationError) {
        monitor.timing()
        monitor.addCategory(key: "failedReason", value: error.errorCode.rawValue)
        monitor.failure()
        monitor.flushSlardar()
    }

    /// 定位结果成功
    func success(location: LarkLocation) {
        /// 定位结果的类型
        monitor.addCategory(key: "resultType", value: location.sourceType.sourceValue)
        /// 定位质量：时效性 打点时间戳定位结果的时间戳的差值 越小表示越好
        monitor.addCategory(key: "resultAging", value: Int(location.location.timestamp.timeIntervalSinceNow))
        /// 定位质量：精确度 期望精确度和定位结果精确度差值 越小表示越好
        monitor.addCategory(key: "accuracyDifference", value: location.location.horizontalAccuracy - request.desiredAccuracy)
        if #available(iOS 15.0, *) {
            /// 是否使用软件模拟定位
            monitor.addCategory(key: "isSimulatedBySoftware", value: location.location.sourceInformation?.isSimulatedBySoftware)
            /// 是否是MFi设备生成的定位
            monitor.addCategory(key: "isProducedByAccessory", value: location.location.sourceInformation?.isProducedByAccessory)
        }
        monitor.success()
        monitor.flushSlardar()
    }
}

private extension LarkLocationSourceType {
    var sourceValue: String {
        switch self {
        case .backup:
            return "backup"
        case .cache:
            return "cache"
        case .normal:
            return "normal"
        }
    }

    /// tea埋点 定位信息数据来源 sdk：SDK cache：缓存 backup：备选
    var sourceTeaValue: String {
        switch self {
        case .backup:
            return "backup"
        case .cache:
            return "cache"
        case .normal:
            return "sdk"
        }
    }
}
/// 持续定位TaskMonitor
final class ContinueLocationTaskMonitor {
    enum FailedReason: String {
        case error
        case timeout
    }
    private let monitor: Monitor
    init(request: LocationRequest,
         serviceType: LocationServiceType) {
        monitor = Monitor(eventName: Homeric.LARK_CORE_LOCATION_CONTINUE_TASK)
            .addLocationRequest(request)
            .addAuthorizationAccuracy()
            .addCategory(key: "serviceType", value: serviceType.rawValue)
        request.monitorCategoryData?.forEach {
            monitor.addCategory(key: $0.key, value: $0.value)
        }
    }

    /// 开启持续定位成功
    func startSuccess() {
        monitor.addCategory(key: "startResult", value: "success")
        monitor.success()
        monitor.flushSlardar()
    }
    /// 开启持续定位失败
    func startFailed(error: LocationAuthorizationError) {
        monitor.addCategory(key: "startFailed", value: error.description)
        monitor.failure()
        monitor.flushSlardar()
    }
    /// 停止持续定位成功
    func stopSuccess() {
        monitor.addCategory(key: "stopResult", value: "success")
        monitor.success()
        monitor.flushSlardar()
    }
    /// 持续定位过程中遇到错误而停止，非用户停止
    func failed(error: LocationError) {
        monitor.addCategory(key: "failedReason", value: error.errorCode.rawValue)
        monitor.failure()
        monitor.flushSlardar()
    }

}

private extension AuthorizationAccuracy {
    var accuracyValue: String {
        switch self {
        case .unknown, .full: return "fine_location"
        case .reduced: return "coarse_location"
        }
    }
}

private extension LocationServiceType {
    var mapType: String {
        switch self {
        case .aMap: return "amap"
        case .apple: return "apple"
        }
    }
}

private extension Monitor {

    @discardableResult
    func addLocationRequest(_ request: LocationRequest) -> Monitor {
        return addCategory(key: "desiredAccuracy", value: request.desiredAccuracy)
            .addCategory(key: "desiredServiceType", value: request.desiredServiceType?.rawValue ?? "")
    }

    @discardableResult
    func addAuthorizationAccuracy() -> Monitor {
        let accuracy = shareLocationAuth().authorizationAccuracy().accuracyValue
        return addCategory(key: "accuracyAuthorization", value: accuracy)
            .addParam(key: "location_accuracy_type", value: accuracy)
    }
}

private extension LocationError {
    static func getRawErrorCode(error: Error?) -> String {
        var rawErrorCode = "Unknown"
        if let clError = error as? CLError {
            rawErrorCode = String(clError.code.rawValue)
        }
#if canImport(AMapLocationKit)
        if let amapError = error as? NSError, let errorCode = AMapLocationErrorCode(rawValue: amapError.code) {
            rawErrorCode = String(errorCode.rawValue)
        }
#endif
        return rawErrorCode
    }
}

final class LocationAuthorizationMonitor {
    private let monitor: Monitor
    init() {
        monitor = Monitor(eventName: Homeric.CORE_LOCATION_SERVICES_ENABLED)
    }
    func start() {
        monitor.setStartTime(Date().timeIntervalSince1970 * 1000)
    }

    func end(isEnabled: Bool, isWaitTimeout: Bool? = nil) {
        monitor.addCategory(key: "isEnabled", value: isEnabled)
        if let isWaitTimeout = isWaitTimeout {
            monitor.addCategory(key: "isWaitTimeout", value: isWaitTimeout)
        }
        monitor.timing()
        monitor.flushSlardar()
    }

}
