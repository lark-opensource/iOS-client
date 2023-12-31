//
//  DaySceneState.swift
//  Calendar
//
//  Created by 张威 on 2020/7/14.
//  Copyright © 2020 ByteDance. All rights reserved.
//

import EventKit
import CTFoundation
import LarkTimeFormatUtils
import UniverseDesignFont

/// DayScene - StoreState

struct DaySceneState {
    // 每一屏有几天（日视图 - 1 天，三日视图 - 3 天，周视图 - 7 天）
    let daysPerScene: Int

    // 冷启动
    let coldLaunchContext: HomeScene.ColdLaunchContext?

    // 当前 julian day
    var currentDay: JulianDay = JulianDayUtil.julianDay(from: Date(), in: .current)

    // 当前 active day
    var activeDay: JulianDay = JulianDayUtil.julianDay(from: Date(), in: .current)

    // 视图时区
    var timeZoneModel: DaySceneTimeZoneModel = DaySceneTimeZoneModel(timeZone: .current, extraWidth: DayScene.UIStyle.Layout.timeZoneRightWidth)

    var additionalTimeZone: DaySceneTimeZoneModel?
}

extension DaySceneState: CustomDebugStringConvertible {
    var debugDescription: String {
        return "daysPerScene: \(daysPerScene), currentDay: \(currentDay), activeDay: \(activeDay), timeZone: \(timeZoneModel.timeZone)"
    }
}

struct DaySceneTimeZoneModel: Equatable {
    var timeZone: TimeZone {
        didSet {
            setTimeZoneWidth()
        }
    }

    private var timeZoneWidth12HourStyle: CGFloat = 0
    private var timeZoneWidth24HourStyle: CGFloat = 0
    private var gmtWidth: CGFloat = 0
    private let extraWidth: CGFloat

    /// timeZone: 被计算宽度的时区
    /// extraWidth: icon宽度及间距
    init(timeZone: TimeZone, extraWidth: CGFloat = 0) {
        self.timeZone = timeZone
        self.extraWidth = extraWidth
        setTimeZoneWidth()
    }

    func getTimeZoneWidth(is12HourStyle: Bool) -> CGFloat {
        return is12HourStyle ? timeZoneWidth12HourStyle : timeZoneWidth24HourStyle
    }

    // 计算视图页header部分时区宽度，由于12小时制时部分语言的的时间字符串会比header中的时区宽度宽，所以取二者最大值
    private mutating func setTimeZoneWidth() {
        let timeZoneAttributes = [NSAttributedString.Key.font: UIFont.cd.dinBoldFont(ofSize: 11)]
        let gmtSize = NSAttributedString(string: timeZone.gmtOffsetDescription, attributes: timeZoneAttributes)
            .boundingRect(with: CGSize(width: 1000, height: 24), context: nil).size
        let time12HourStyleWidth = calculateTimeZoneWidth(is12HourStyle: true)
        self.timeZoneWidth12HourStyle = ceil((gmtSize.width + extraWidth) > time12HourStyleWidth ? gmtSize.width : time12HourStyleWidth - extraWidth)

        let time24HourStyleWidth = calculateTimeZoneWidth(is12HourStyle: false)
        self.timeZoneWidth24HourStyle = ceil((gmtSize.width + extraWidth) > time24HourStyleWidth ? gmtSize.width : time24HourStyleWidth - extraWidth)
    }

    private func calculateTimeZoneWidth(is12HourStyle: Bool) -> CGFloat {
        // 中午12:30时宽度较宽，以此为基准
        let string = "2023-07-01 12:30:00"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let customOptions = Options(
            is12HourStyle: is12HourStyle,
            timePrecisionType: .minute,
            shouldRemoveTrailingZeros: true
        )
        let day = dateFormatter.date(from: string) ?? Date()
        let time12HourStyle = TimeFormatUtils.formatTime(from: day, with: customOptions)
        let timeAttributes = [NSAttributedString.Key.font: UDFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)]
        return NSAttributedString(string: time12HourStyle, attributes: timeAttributes)
            .boundingRect(with: CGSize(width: 1000, height: 24), context: nil).size.width
    }

    static func == (lhs: DaySceneTimeZoneModel, rhs: DaySceneTimeZoneModel) -> Bool {
        return lhs.timeZone.identifier == rhs.timeZone.identifier
    }
}
