//
//  DayInstanceSource.swift
//  Calendar
//
//  Created by 张威 on 2020/9/3.
//

import RxSwift
import EventKit

// MARK: 全天日程日程数据源

struct DayAllDayLayoutedInstance {
    let instance: BlockDataProtocol
    let dayRange: JulianDayRange
}

protocol DayAllDayInstanceSource {

    /// 全天日程需要更新时的通知
    var rxAllDayInstanceUpdated: PublishSubject<Void> { get }

    /// 根据 dayRange 和 timeZone 获取全天的 instances
    /// - Parameters:
    ///   - dayRange: 目标 dayRange
    ///   - timeZone: 目标 timeZone
    ///   - fromColdLaunch: 是否来自于冷启动（冷启动的请求会有特别的处理）
    func rxAllDayInstances(
        for dayRangeWrapper: CAValue<JulianDayRange>,
        in timeZone: TimeZone,
        fromColdLaunch: Bool) -> RxReturn<[DayAllDayLayoutedInstance]>

}

extension DayAllDayInstanceSource {

    /// 根据 dayRange 和 timeZone 获取全天的 instances（不走冷启动渠道）
    /// - Parameters:
    ///   - dayRange: 目标 dayRange
    ///   - timeZone: 目标 timeZone
    func rxAllDayInstances(for dayRange: CAValue<JulianDayRange>, in timeZone: TimeZone)
        -> RxReturn<[DayAllDayLayoutedInstance]> {
        rxAllDayInstances(for: dayRange, in: timeZone, fromColdLaunch: false)
    }

}

enum BlockDataType: String {
    case event
    case timeBlock
    case instanceEntity
}

enum BlockDataEntityType {
    case event(Instance)
    case instanceEntity(CalendarEventInstanceEntity)
    case timeBlock(TimeBlockModel)
    case none
}

// 视图页基础数据类型
protocol BlockDataProtocol {
    var type: BlockDataType { get }
    var id: String { get }
    var sortKey: String { get }
    var title: String { get }
    
    var startDay: Int32 { get }
    var endDay: Int32 { get }
    var startTime: Int64 { get }
    var endTime: Int64 { get }
    var isAllDay: Bool { get }
    func shouldTreatedAsAllDay() -> Bool
}

extension BlockDataProtocol {
    @discardableResult
    func process<R>(_ task: (BlockDataEntityType) -> R) -> R {
        if let instance = self as? Instance {
            task(.event(instance))
        } else if let timeBlockModel = self as? TimeBlockModel {
            task(.timeBlock(timeBlockModel))
        } else if let entity = self as? CalendarEventInstanceEntity {
            task(.instanceEntity(entity))
        } else {
            task(.none)
        }
    }
    
    func process<R>(_ task: (BlockDataEntityType) -> R?) -> R? {
        if let instance = self as? Instance {
            task(.event(instance))
        } else if let timeBlockModel = self as? TimeBlockModel {
            task(.timeBlock(timeBlockModel))
        } else if let entity = self as? CalendarEventInstanceEntity {
            task(.instanceEntity(entity))
        } else {
            task(.none)
        }
    }
    
    func shouldTreatedAsAllDay() -> Bool { false }
}

extension Instance: BlockDataProtocol {
    var startDay: Int32 {
        Int32(getStartDay())
    }
    
    var endDay: Int32 {
        Int32(getEndDay())
    }
    var type: BlockDataType { .event }
    var id: String { self.uniqueId }
    var sortKey: String { uniqueId }
    var isAllDay: Bool {
        switch self {
        case .local(let localInstance):
            return localInstance.isAllDay
        case .rust(let rustInstance):
            return rustInstance.isAllDay
        }
    }
}

extension TimeBlockModel: BlockDataProtocol {
    var sortKey: String { id }
    
    var type: BlockDataType { .timeBlock }
}

struct DayNonAllDayLayoutedInstance {
    let instance: BlockDataProtocol
    let layout: Rust.InstanceLayout
}

protocol DayNonAllDayInstanceSource {

    /// 非全天日程需要更新时的通知
    var rxNonAllDayInstanceUpdated: PublishSubject<Void> { get }

    /// 根据 dayRange 和 timeZone 获取非全天的 instances
    /// - Parameters:
    ///   - dayRange: 目标 dayRange
    ///   - timeZone: 目标 timeZone
    ///   - fromColdLaunch: 是否来自于冷启动（冷启动的请求会有特别的处理）
    func rxNonAllDayInstances(for dayRange: CAValue<JulianDayRange>, in timeZone: TimeZone, fromColdLaunch: Bool)
        -> RxReturn<CAValue<[JulianDay: [DayNonAllDayLayoutedInstance]]>>

}

extension DayNonAllDayInstanceSource {

    /// 根据 dayRange 和 timeZone 获取非全天的 instances（不走冷启动渠道）
    /// - Parameters:
    ///   - dayRange: 目标 dayRange
    ///   - timeZone: 目标 timeZone
    func rxNonAllDayInstances(for dayRangeWrapper: CAValue<JulianDayRange>, in timeZone: TimeZone)
        -> RxReturn<CAValue<[JulianDay: [DayNonAllDayLayoutedInstance]]>> {
        rxNonAllDayInstances(for: dayRangeWrapper, in: timeZone, fromColdLaunch: false)
    }

    /// 根据 day 和 timeZone 获取非全天的 instances（不走冷启动渠道）
    /// - Parameters:
    ///   - dayRange: 目标 dayRange
    ///   - timeZone: 目标 timeZone
    func rxNonAllDayInstances(
        for day: JulianDay,
        in timeZone: TimeZone,
        loggerModel: CaVCLoggerModel
    ) -> RxReturn<CAValue<[DayNonAllDayLayoutedInstance]>> {
        return rxNonAllDayInstances(for: .init(day..<day + 1, loggerModel), in: timeZone)
            .map { dictWrapper -> CAValue<[DayNonAllDayLayoutedInstance]> in
                assert(Array(dictWrapper.value.keys) == [day])
                return .init(dictWrapper.value[day] ?? [], dictWrapper.loggerModel)
            }
    }
}
