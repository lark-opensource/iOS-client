//
//  TimeScale.swift
//  Calendar
//
//  Created by 张威 on 2020/8/14.
//

import Foundation

/// 时间刻度（24 小时范围内的时间刻度）

struct TimeScale {
    /// Point 和 Offset 是基本单位
    /// Point 描述某一个时间段一共有 x 个 points
    /// Offset 描述某个时刻对应的 point
    typealias Point = Int
    typealias Offset = Int

    // 每秒对应 1 个 point
    static let pointsPerSecond = 1
    // 每小时有 3600 个 points
    static let pointsPerMinute = 60
    // 每小时有 3600 个 points
    static let pointsPerHour = 3600

    /// 偏移
    let offset: Offset

    init?(offset: Offset) {
        guard offset >= Self.minOffset && offset <= Self.maxOffset else { return nil }
        self.offset = offset
    }

    init(refOffset: Offset) {
        offset = max(Self.minOffset, min(Self.maxOffset, refOffset))
    }

    static let minOffset: Offset = 0
    static let maxOffset: Offset = Self.pointsPerHour * 24
    static let mininum = TimeScale(offset: Self.minOffset)!
    static let maxinum = TimeScale(offset: Self.maxOffset)!
}

extension TimeScale: CustomDebugStringConvertible {
    var debugDescription: String {
        return "offset: \(offset)"
    }
}

// MARK: Calculation

extension TimeScale {

    func adding(_ points: Point) -> TimeScale {
        return TimeScale(refOffset: offset + points)
    }

}

// MARK: Equatable & Comparable

extension TimeScale: Equatable {

    static func == (lhs: Self, rhs: Self) -> Bool {
        return (lhs.offset == rhs.offset)
    }

}

extension TimeScale: Comparable {

    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.offset < rhs.offset
    }

}

// MARK: Components

extension TimeScale {

    typealias Components = (hour: Int, minute: Int, second: Int)

    init?(components: Components) {
        let (hour, minute, second) = components
        guard hour >= 0 && hour <= 24
              && minute >= 0 && minute < 60
              && second >= 0 && second < 60 else {
            return nil
        }
        self.init(offset: hour * Self.pointsPerHour + minute * Self.pointsPerMinute + second)
    }

    func components() -> Components {
        let hour = (offset - Self.minOffset) / Self.pointsPerHour
        let minute = (offset - Self.minOffset) % Self.pointsPerHour / Self.pointsPerMinute
        let second = (offset - Self.minOffset) % Self.pointsPerMinute
        return (hour, minute, second)
    }

}

// MARK: Util

extension TimeScale {
    /// 粒度
    enum Granularity: Int {
        // 1 分钟
        case hour_60 = 60 // 3_600 / 60
        // 5 分钟
        case hour_12 = 300 // 3_600 / 12
        // 1/4 小时（一刻钟）
        case hour_4 = 900   // 3_600 / 4
        // 1/2 小时（半小时）
        case hour_2 = 1800  // 3_600 / 2
    }

    /// 根据粒度四舍五入
    ///  eg: 12:13 对应的刻度 => 12:15 对应的刻度（粒度为 .quarter）
    ///      12:13 对应的刻度 => 12:00 对应的刻度（粒度为 .half）
    func round(toGranularity granularity: Granularity) -> Self {
        let multiple = Foundation.round(Float(offset) / Float(granularity.rawValue))
        let offset = Int(multiple) * granularity.rawValue
        return Self(refOffset: offset)
    }

    /// 根据粒度向下取整
    ///  eg: 12:33 对应的刻度 => 12:15 对应的刻度（粒度为 .quarter）
    ///      12:33 对应的刻度 => 12:30 对应的刻度（粒度为 .half）
    func floor(toGranularity granularity: Granularity) -> Self {
        let multiple = Foundation.floor(Float(offset) / Float(granularity.rawValue))
        let offset = Int(multiple) * granularity.rawValue
        return Self(refOffset: offset)
    }

}

// MARK: Format

typealias TimeScaleRange = Range<TimeScale>

extension TimeScaleRange {

    var points: Int { upperBound.offset - lowerBound.offset }

}
