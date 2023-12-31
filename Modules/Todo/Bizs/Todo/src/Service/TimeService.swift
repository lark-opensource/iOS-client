//
//  TimeService.swift
//  TodoInterface
//
//  Created by 张威 on 2020/11/11.
//

import RxSwift
import RxCocoa
import CTFoundation

/// Time Service
/// 为整个 Todo 业务提供 time 相关信息/功能

protocol TimeService: AnyObject {
    /// 十二小时制
    var rx12HourStyle: BehaviorRelay<Bool> { get }

    /// 当前天
    var rxCurrentDay: BehaviorRelay<JulianDay> { get }

    /// 当前时区
    var rxTimeZone: BehaviorRelay<TimeZone> { get }

    /// 全局唯一的 calendar
    var calendar: Calendar { get }

    var utcTimeZone: TimeZone { get }
}

/// UTC 时区
let utcTimeZone: TimeZone = (TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0))!
