//
//  UDDatePicker+Config.swift
//  UniverseDesignDatePicker
//
//  Created by LiangHongbin on 2020/12/14.
//

import UIKit
import Foundation
import EventKit
import UniverseDesignFont

/// 滚轮配置
public struct UDWheelsStyleConfig {
    /// 选择时间/日期类型
    public enum WheelModel {
        /// e.g.:  [11月14日 周六]—[04]—[00] (Nov 18 Wed 05 00<支持24h>)
        case dayHourMinute(twelveHourScale: [Double] = [3.0, 1.0, 1.0, 1.0], twentyFourHourScale: [Double] = [2.0, 1.0, 1.0])
        /// e.g.:  [上午]—[11]—[20]（支持24h）
        case hourMinute
        /// e.g.:  [09]—[15]—[am]（支持24h）TodoTask
        case hourMinuteCenter
        /// e.g.:  [2018年]—[3月]—[24日]
        case yearMonthDay
        /// e.g.:  [2020年]—[10月]—[31日（周日）]
        case yearMonthDayWeek
        /// e.g.:  [2021年]—[03月]—[12日]—[08]（不支持12h）ByteMoments
        case yearMonthDayHour
        /// e.g.:  [2021年] 红包
        case year
    }
    /// 默认最小可选 1900.01.01 00:00
    public static let defaultMinDate = JulianDayUtil.date(from: JulianDayUtil.julianDayFrom1900_01_01)
    /// 默认最大可选 2099.12.31 23:59
    public static let defaultMaxDate = JulianDayUtil.date(from: JulianDayUtil.julianDayFrom2100_01_01) - 1
    /// 滚轮类型
    public var mode: WheelModel = .yearMonthDay
    /// 滚轮最大展示行数
    public var maxDisplayRows: Int
    /// 滚轮整体高度
    public var pickerHeight: CGFloat
    /// 是否为12小时制
    public var is12Hour: Bool = true
    /// 字体颜色
    public var textColor: UIColor = UDDatePickerTheme.wheelPickerPrimaryTextNormalColor
    /// 字体
    public var textFont: UIFont = UDFont.body0
    /// 是否显示聚焦分割线
    public var showSepeLine: Bool = true
    /// 时间间隔[分钟滚轮]
    public var minInterval: Int = 5
    /// 滚轮背景颜色
    public var pickerBackgroundColor: UIColor = UDDatePickerTheme.wheelPickerBackgroundColor

    /// 滚轮配置 init，picker 高度根据内容自撑
    /// - Parameters:
    ///   - mode: 滚轮选择器类型，默认 年月日
    ///   - maxDisplayRows: 最大显示行数，默认为 3（picker 高度自撑）
    ///   - is12Hour: 是否12小时制，默认为 true
    ///   - showSepeLine: 是否显示分割线，默认为 true
    ///   - minInterval: 含分钟滚轮时间间隔，默认为 5 （要求为 60 的因数）
    ///   - textColor: 显示颜色，默认 N900(neutralColor12)
    ///   - textFont: 显示字体，默认 17号(title5)
    ///   - backgroundColor: 滚轮背景颜色，默认 UDColor.bgBody
    public init(mode: WheelModel = .yearMonthDay,
                maxDisplayRows: Int = 3,
                is12Hour: Bool = true,
                showSepeLine: Bool = true,
                minInterval: Int = 5,
                textColor: UIColor = UDDatePickerTheme.wheelPickerPrimaryTextNormalColor,
                textFont: UIFont = UDFont.body0,
                backgroundColor: UIColor = UDDatePickerTheme.wheelPickerBackgroundColor) {
        self.mode = mode
        self.maxDisplayRows = maxDisplayRows
        self.pickerHeight = CGFloat(48 * maxDisplayRows)
        self.is12Hour = is12Hour
        self.textColor = textColor
        self.textFont = textFont
        self.showSepeLine = showSepeLine
        self.minInterval = minInterval
        self.pickerBackgroundColor = backgroundColor
    }

    /// 滚轮配置 init，picker 高度自定义
    /// - Parameters:
    ///   - mode: 滚轮选择器类型，默认 年月日
    ///   - pickerHeight: picker 自定义高度
    ///   - is12Hour: 是否12小时制，默认为 true
    ///   - showSepeLine: 是否显示分割线，默认为 true
    ///   - minInterval: 含分钟滚轮时间间隔，默认为 5 （要求为 60 的因数）
    ///   - textColor: 显示颜色，默认 N900(neutralColor12)
    ///   - textFont: 显示字体，默认 17号(title5)
    ///   - backgroundColor: 滚轮背景颜色，默认 UDColor.bgBody
    public init(mode: WheelModel = .yearMonthDay,
                pickerHeight: CGFloat,
                is12Hour: Bool = true,
                showSepeLine: Bool = true,
                minInterval: Int = 5,
                textColor: UIColor = UDDatePickerTheme.wheelPickerPrimaryTextNormalColor,
                textFont: UIFont = UDFont.body0,
                backgroundColor: UIColor = UDDatePickerTheme.wheelPickerBackgroundColor) {
        self.mode = mode
        // 减去 2*8 的上下留白
        self.pickerHeight = pickerHeight - 16
        self.maxDisplayRows = -1
        self.is12Hour = is12Hour
        self.textColor = textColor
        self.textFont = textFont
        self.showSepeLine = showSepeLine
        self.minInterval = minInterval
        self.pickerBackgroundColor = backgroundColor
    }
}
/// 月历配置
public struct UDCalendarStyleConfig {
    /// 翻页是是否自动勾选当月 1 号
    public var autoSelectedDate: Bool
    /// 当月是否固定 6 周
    public var rowNumFixed: Bool
    /// 月历 dayCell 高度
    public var dayCellHeight: CGFloat
    /// 月历 cell 类型，用于 collectionView 注册
    public var dayCellClass: AnyClass
    /// 月历每周的第一天
    public var firstWeekday: EKWeekday

    /// 月历配置 init，月历高度根据内容自撑
    /// - Parameters:
    ///   - rowNumFixed: 当月是否固定 6 周
    ///   - autoSelectedDate: 翻页是是否自动勾选当月 1 号
    ///   - firstWeekday: 月历每周的第一天
    ///   - dayCellHeight: 月历单个 dayCell 高度（picker 高度自撑）
    ///   - dayCellClass: 月历 cell 类型，用于 collectionView 注册
    public init(rowNumFixed: Bool = false,
                autoSelectedDate: Bool = true,
                firstWeekday: EKWeekday = .sunday,
                dayCellHeight: CGFloat = 32,
                dayCellClass: AnyClass = UDCalendarPickerCell.self) {
        self.rowNumFixed = rowNumFixed
        self.autoSelectedDate = autoSelectedDate
        self.firstWeekday = firstWeekday
        self.dayCellHeight = dayCellHeight
        self.dayCellClass = dayCellClass
    }
}
