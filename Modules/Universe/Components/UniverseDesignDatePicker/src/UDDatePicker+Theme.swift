//
//  UDDatePicker+Theme.swift
//  UniverseDesignDatePicker
//
//  Created by LiangHongbin on 2020/12/14.
//

import UIKit
import Foundation
import UniverseDesignColor

/// UDColor Name Extension
public extension UDColor.Name {

    /// WheelPicker title Color Key
    static let wheelPickerTitlePrimaryNormalColor = UDColor.Name("date Picker-title-primary-normal-color")

    /// WheelPicker cancel btn Color Key
    static let wheelPickerBtnSeconTextNormalColor = UDColor.Name("date Picker-btn-secondary-text-normal-color")

    /// WheelPicker complete btn Color Key
    static let wheelPickerBtnPrimaryTextNormalColor = UDColor.Name("date Picker-btn-primary-text-normal-color")

    /// WheelPicker background Color Key
    static let wheelPickerBackgroundColor = UDColor.Name("date Picker-bg-color")

    /// WheelPicker seperator line Color Key
    static let wheelPickerLinePrimaryBgNormalColor = UDColor.Name("date Picker-line-primary-bg-normal-color")

    /// WheelPicker text Color Key
    static let wheelPickerPrimaryTextNormalColor = UDColor.Name("date Picker-primary-text-normal-color")

    /// CalendarPicker today selected bg color key
    static let calendarPickerTodaySelectedBgColor = UDColor.Name("calendar_today-btn-primary-bg-select-color")

    /// CalendarPicker today text color key
    static let calendarPickerTodayTextColor = UDColor.Name("calendar_today-btn-primary-text-normal-color")

    /// CalendarPicker today selected text color key
    static let calendarPickerTodaySelectedTextColor = UDColor.Name("calendar_today-btn-primary-text-select-color")

    /// CalendarPicker current selected bg color key
    static let calendarPickerCurrentMonthBgColor = UDColor.Name("calendar_date-btn-primary-bg-select-color")

    /// CalendarPicker not current text color key
    static let calendarPickerOuterMonthTextColor = UDColor.Name("calendar_date-btn-secondary-text-normal-color")

    /// CalendarPicker current text color key
    static let calendarPickerCurrentMonthTextColor = UDColor.Name("calendar_date-btn-primary-text-normal-color")

    /// CalendarPicker selected week text color key
    static let calendarPickerWeekSelectedTextColor = UDColor.Name("calendar_week-text-primary-select-color")
}

/// UDDatePicker Color Theme
public struct UDDatePickerTheme {

    /// WheelPicker title Color Key
    public static var wheelPickerTitlePrimaryNormalColor: UIColor {
        return UDColor.getValueByKey(.wheelPickerTitlePrimaryNormalColor) ?? UDColor.textTitle
    }

    /// WheelPicker cancel btn Color Key
    public static var wheelPickerBtnSeconTextNormalColor: UIColor {
        return UDColor.getValueByKey(.wheelPickerBtnSeconTextNormalColor) ?? UDColor.textTitle
    }

    /// WheelPicker complete btn Color Key
    public static var wheelPickerBtnPrimaryTextNormalColor: UIColor {
        return UDColor.getValueByKey(.wheelPickerBtnPrimaryTextNormalColor) ?? UDColor.primaryContentDefault
    }

    /// WheelPicker background Color Key
    public static var wheelPickerBackgroundColor: UIColor {
        return UDColor.getValueByKey(.wheelPickerBackgroundColor) ?? UDColor.bgBody
    }

    /// WheelPicker seperator line Color Key
    public static var wheelPickerLinePrimaryBgNormalColor: UIColor {
        return UDColor.getValueByKey(.wheelPickerLinePrimaryBgNormalColor) ?? UDColor.lineBorderCard
    }

    /// WheelPicker text  Color Key
    public static var wheelPickerPrimaryTextNormalColor: UIColor {
        return UDColor.getValueByKey(.wheelPickerPrimaryTextNormalColor) ?? UDColor.textTitle
    }

    /// CalendarPicker today selected bg color key
    public static var calendarPickerTodaySelectedBgColor: UIColor {
        return UDColor.getValueByKey(.calendarPickerTodaySelectedBgColor) ?? UDColor.primaryContentDefault
    }

    /// CalendarPicker today text color key
    public static var calendarPickerTodayTextColor: UIColor {
        return UDColor.getValueByKey(.calendarPickerTodayTextColor) ?? UDColor.primaryContentDefault
    }

    /// CalendarPicker today selected text color key
    public static var calendarPickerTodaySelectedTextColor: UIColor {
        return UDColor.getValueByKey(.calendarPickerTodaySelectedTextColor) ?? UDColor.primaryOnPrimaryFill
    }

    /// CalendarPicker current selected bg color key
    public static var calendarPickerCurrentMonthBgColor: UIColor {
        return UDColor.getValueByKey(.calendarPickerCurrentMonthBgColor) ?? UDColor.lineBorderCard
    }

    /// CalendarPicker pre/next text color key
    public static var calendarPickerOuterMonthTextColor: UIColor {
        return UDColor.getValueByKey(.calendarPickerOuterMonthTextColor) ?? UDColor.textPlaceholder
    }

    /// CalendarPicker current text color key
    public static var calendarPickerCurrentMonthTextColor: UIColor {
        return UDColor.getValueByKey(.calendarPickerCurrentMonthTextColor) ?? UDColor.textTitle
    }

    /// CalendarPicker selected week text color key
    public static var calendarPickerWeekSelectedTextColor: UIColor {
        return UDColor.getValueByKey(.calendarPickerWeekSelectedTextColor) ?? UDColor.primaryContentDefault
    }
}
