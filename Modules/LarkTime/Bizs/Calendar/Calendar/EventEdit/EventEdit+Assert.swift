//
//  EventEdit+Assert.swift
//  Calendar
//
//  Created by 张威 on 2020/12/21.
//

import LKCommonsTracker

extension EventEdit {
    enum AssertType: String {
        /// 未定义（默认）
        case `default`
        /// 保存失败
        case saveFailed
        /// 切换日历失败
        case switchCalendarFailed
    }

    static func assert(
        _ condition: @autoclosure () -> Bool,
        _ message: @autoclosure () -> String = String(),
        type: AssertType = .default,
        extra: [AnyHashable: Any] = .init(),
        file: StaticString = #fileID,
        line: UInt = #line
    ) {
        guard !condition() else { return }
        let msg = message()
        EventEdit.logger.error("assert. type: \(type.rawValue), msg: \(msg)")
        Swift.assert(false, msg, file: file, line: line)
        var extra = extra
        extra["msg"] = msg
        Tracker.post(SlardarEvent(
            name: "cal_event_edit_assert",
            metric: [:],
            category: ["type": type.rawValue],
            extra: extra
        ))
    }

    static func assertionFailure(
        _ message: @autoclosure () -> String = String(),
        type: AssertType = .default,
        extra: [AnyHashable: Any] = .init(),
        file: StaticString = #fileID,
        line: UInt = #line
    ) {
        self.assert(false, message(), type: type, extra: extra, file: file, line: line)
    }

}
