//
//  DayScene.swift
//  Calendar
//
//  Created by 张威 on 2020/8/25.
//

import UIKit
import UniverseDesignIcon
import Foundation
import LKCommonsLogging
import EventKit
import CTFoundation
import LarkUIKit

struct DayScene {
    // logger for day scene
    static let logger = Logger.log(Self.self, category: "Calendar.DayScene")

    static let localIcon = UIImage.cd.image(named: "localFlagShape").withRenderingMode(.alwaysTemplate)

    static let exchangeIcon = UIImage.cd.image(named: "exchangeFlagShape").withRenderingMode(.alwaysTemplate)

    static let googleIcon = UIImage.cd.image(named: "googleFlagShape_highlighted").withRenderingMode(.alwaysTemplate)

    // ui style for day scene
    enum UIStyle {}
}

extension DayScene.UIStyle {

    enum Const {
        // 全天日程高度变化的动画时长
        static let allDayAnimationDuration: TimeInterval = 0.15
        static let dayPageCount = 2_000_000
    }

    enum Layout {

        // 左侧部分的宽度，包括：
        //  - header.timeZoneView
        //  - allDay.tipView
        //  - nonAllDay.timeScaleView
        static let leftPartWidth: CGFloat = 56

        // 刻度画布（包括非全天）
        static let timeScaleCanvas = (
            // paddingTop and paddingBottom
            vPadding: (top: CGFloat(20), bottom: CGFloat(20)),
            // 每个小时的高度
            heightPerHour: CGFloat(50)
        )

        // 刻度画布高度
        static var timeScaleCanvasHeight: CGFloat {
            timeScaleCanvas.vPadding.top + timeScaleCanvas.vPadding.bottom + timeScaleCanvas.heightPerHour * 24
        }

        // head中timeZone的边距
        static let timeZonePadding: CGFloat = Display.pad ? 12 : 4

        // header中时区和辅助时区的间距
        static let timeZonesSpacing: CGFloat = 4

        // header中时区右侧宽度，包括
        //  - timeZone的icon的宽度
        //  - timeZone与icon的间距
        static let timeZoneRightWidth: CGFloat = 8

        // 展示辅助时区时的除GMT文案宽度的其余宽度，包括间距和icon
        static let showAdditionalTimeZoneSpacingWidth = DayScene.UIStyle.Layout.timeZonePadding * 2
        + DayScene.UIStyle.Layout.timeZonesSpacing
        + DayScene.UIStyle.Layout.timeZoneRightWidth

        // 隐藏辅助时区时的除GMT文案宽度的其余宽度，包括间距和icon
        static let hiddenAdditionalTimeZoneSpacingWidth = DayScene.UIStyle.Layout.timeZonePadding * 2
        + DayScene.UIStyle.Layout.timeZoneRightWidth
    }

}

extension DayScene {
    typealias LayoutedText = (text: NSAttributedString, frame: CGRect)
}

extension DayScene {
    typealias ViewSetting = EventViewSetting
}

// MARK: Converting Between JulianDay and PageIndex

extension DayScene {

    static let daysPerWeek = 7
    static let baseJulianDay = JulianDayUtil.julianDayFrom1900_01_01

    static func pageIndex(from julianDay: JulianDay) -> PageIndex {
        return julianDay - baseJulianDay
    }

    static func julianDay(from pageIndex: PageIndex) -> JulianDay {
        return pageIndex + baseJulianDay
    }

    static func julianDayRange(from pageRange: PageRange) -> JulianDayRange {
        let fromDay = julianDay(from: pageRange.lowerBound)
        let toDay = julianDay(from: pageRange.upperBound)
        return fromDay..<toDay
    }

    static func pageRange(from julianDayRange: JulianDayRange) -> PageRange {
        let fromPage = pageIndex(from: julianDayRange.lowerBound)
        let toPage = pageIndex(from: julianDayRange.upperBound)
        return fromPage..<toPage
    }

    // 为节省计算开支，对 baseDayRange 根据 firstWeekday 做一个缓存
    private static var baseJulianDayRangeMap = [EKWeekday: JulianDayRange]()

    /// 根据 firstWeekday 计算与目标 JulianDay 在同一个 week 的 JulianDayRange
    static func julianDayRange(inSameWeekAs julianDay: JulianDay, with firstWeekday: EKWeekday) -> JulianDayRange {
        var baseDayRange: JulianDayRange! = baseJulianDayRangeMap[firstWeekday]
        if baseDayRange == nil {
            baseDayRange = JulianDayUtil.julianDayRange(inSameWeekAs: baseJulianDay, with: firstWeekday)
            baseJulianDayRangeMap[firstWeekday] = baseDayRange
        }
        let index = (julianDay - baseDayRange.lowerBound) / daysPerWeek
        let fromDay = baseDayRange.lowerBound + index * daysPerWeek
        return fromDay..<fromDay + daysPerWeek
    }

    static func julianDayRange(inWeeksAs julianDayRange: JulianDayRange, with firstWeekday: EKWeekday) -> JulianDayRange {
        guard julianDayRange.count >= 1 else {
            return JulianDayUtil.julianDayRange(inSameWeekAs: julianDayRange.lowerBound, with: firstWeekday)
        }
        let fromDay = self.julianDayRange(inSameWeekAs: julianDayRange.lowerBound, with: firstWeekday).lowerBound
        let toDay = self.julianDayRange(inSameWeekAs: julianDayRange.upperBound - 1, with: firstWeekday).upperBound
        return fromDay..<toDay
    }

}
