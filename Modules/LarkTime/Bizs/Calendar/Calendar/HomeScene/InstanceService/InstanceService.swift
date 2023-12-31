//
//  InstanceService.swift
//  Calendar
//
//  Created by 张威 on 2020/8/16.
//

import RxSwift
import RxRelay
import EventKit

/// RxReturn 用于描述返回值

enum RxReturn<Type> {
    // 同步值
    case value(Type)
    // 异步值
    case rxValue(Single<Type>)

    func map<TargetType>(transform: @escaping ((Type) -> TargetType))
        -> RxReturn<TargetType> {
        switch self {
        case .value(let v): return .value(transform(v))
        case .rxValue(let rxV): return .rxValue(rxV.map(transform))
        }
    }

    func asObservable() -> Observable<Type> {
        switch self {
        case .value(let v): return .just(v)
        case .rxValue(let rxV): return rxV.asObservable()
        }
    }
}

// MARK: Cache Strategy

/// Instance 缓存策略
struct InstanceCacheStrategy {
    // 时区
    var timeZone: TimeZone
    // 磁盘缓存范围
    var diskCacheRange: JulianDayRange
    // 内存缓存范围
    var memoryCacheDays: Set<JulianDay>
}

// 为 InstanceService 提供缓存策略
protocol InstanceCacheStrategyProvider: AnyObject {
    var rxInstanceCacheStrategy: BehaviorRelay<InstanceCacheStrategy>? { get }
}

// MARK: Cold Launch

struct ColdLaunchInstances {
    var instanceMap: DayInstanceMap
    // true: 表示 instances 来自于 rust；false: 表示 instances 来自于 snapshot
    var isFromRust: Bool
    var loggerModel: CaVCLoggerModel
}

protocol InstanceService: AnyObject {
    // 缓存策略
    var cacheStrategy: InstanceCacheStrategy? { get set }

    var instanceUpdated: PublishSubject<Void> { get }

    /// 根据 dayRange 和 timeZone 获取 instances
    ///
    /// - Parameters:
    ///   - dayRange: 目标 julianDay range
    ///   - timeZone: 目标 timeZone
    func rxInstance(for dayRangeWrapper: CAValue<JulianDayRange>, in timeZone: TimeZone) -> RxReturn<CAValue<DayInstanceMap>>

    /// 根据 dayRange 和 timeZone 获取冷启动数据
    ///
    /// - Parameters:
    ///   - dayRange: 目标 julianDay range
    ///   - timeZone: 目标 timeZone
    func rxColdLaunchInstance(for dayRangeWrapper: CAValue<JulianDayRange>, in timeZone: TimeZone) -> RxReturn<CAValue<ColdLaunchInstances>>
}

extension InstanceService {

    var cacheStrategy: InstanceCacheStrategy? { nil }
}
