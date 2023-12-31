//
//  DayScene+Assert.swift
//  Calendar
//
//  Created by 张威 on 2020/9/15.
//

import Foundation
import LKCommonsTracker

// DayScene 告警，告警信息上报到 Slardar

extension DayScene {

    enum AssertType: String {
        /// 未定义（默认）
        case `default`
        /// 准备全天日程 viewData 失败
        case prepareAllDayViewDataFailed
        /// 准备非全天日程 viewData 失败
        case prepareNonAllDayViewDataFailed
        /// 日程块无法点击
        case showDetailFailed
        /// 日程块按钮无法点击
        case tapIconTappedFailed
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
        DayScene.logger.error("assert. type: \(type.rawValue), msg: \(msg)")
//        Swift.assert(false, msg, file: file, line: line)
        var extra = extra
        extra["msg"] = msg
        Tracker.post(SlardarEvent(
            name: "cal_day_scene_assert",
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
