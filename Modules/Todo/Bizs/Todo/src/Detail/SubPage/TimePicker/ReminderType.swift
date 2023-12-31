//
//  ReminderType.swift
//  Todo
//
//  Created by 白言韬 on 2021/7/13.
//

import Foundation
import LKCommonsLogging

struct TimePicker { }

// MARK: - Logger

extension TimePicker {
    static let logger = Logger.log(TimePicker.self, category: "Todo.TimePicker")
}

// MARK: - Assert

extension TimePicker {

    enum AssertType: String {
        /// 未定义（默认）
        case `default`
        /// 数组越界
        case outOfRange
    }

    // nolint: long parameters
    static func assert(
        _ condition: @autoclosure () -> Bool,
        _ message: @autoclosure () -> String = String(),
        type: AssertType = .default,
        extra: [AnyHashable: Any] = .init(),
        file: String = #fileID,
        line: Int = #line
    ) {
        guard !condition() else { return }
        let msg = message()
        TimePicker.logger.error("msg: \(msg), type: \(type), extra: \(extra)", file: file, line: line)
        let assertConfig = AssertReporter.AssertConfig(scene: "timePicker", event: type.rawValue)
        AssertReporter.report(msg, extra: extra, config: assertConfig, file: file, line: line)
        Swift.assertionFailure()
    }
    // enable-lint: long parameters

    static func assertionFailure(
        _ message: @autoclosure () -> String = String(),
        type: AssertType = .default,
        extra: [AnyHashable: Any] = .init(),
        file: String = #fileID,
        line: Int = #line
    ) {
        self.assert(false, message(), type: type, extra: extra, file: file, line: line)
    }
}

protocol ReminderType {
    var minutes: Int64 { get }
}

/// 提醒时间枚举，用法：
/// fiveMinutesBefore = 5 -> 当前时间 - 5分钟 = 提醒时间
/// onDayOfEventAt9am = -540 -> 当前时间 - (-540分钟) = 提醒时间
enum NonAllDayReminder: Int64, ReminderType {
    /// 保留仅做兼容，不提醒应使用空数组表达，需要在未来重构掉
    case noAlert = -1

    case atTimeOfEvent = 0
    case fiveMinutesBefore = 5
    case aQuarterBefore = 15
    case halfAnHourBefore = 30
    case anHourBefore = 60
    case twoHoursBefore = 120
    case aDayBefore = 1_440
    case twoDaysBefore = 2_880
    case aWeekBefore = 10_080

    var minutes: Int64 { rawValue }
}

enum AllDayReminder: Int64, ReminderType {
    case onDayofEventAt6pm = -1080
    case onDayOfEventAt9am = -540
    case aDayBeforeAt9am = 900
    case twoDaysBeforeAt9am = 2_340
    case aWeekBeforeAt9am = 9_540

    var minutes: Int64 { rawValue }
}

struct OuterReminder: ReminderType {
    var minutes: Int64
}

/// 控制 picker 的显隐状态，最多同时显示一个 picker
enum PickerState {
    case startTime
    case dueTime
    case reminder
    case none
}
