//
//  CalendarCustomUDColorUtils.swift
//  Calendar
//
//  Created by pluto on 2023/2/6.
//

import UIKit
import Foundation
import UniverseDesignColor

extension UDColor.Name {
    static let calendarRSVPCardReactionTagBgColor = UDColor.Name("calendar-rsvp-card-reaction-tag-bgcolor")
    static let calendarRSVPCardAcceptBtnBgColor = UDColor.Name("calendar-rsvp-card-accept-btn-bgcolor")
    static let calendarRSVPCardTagBgColor = UDColor.Name("calendar-rsvp-card-tag-bgcolor")
    static let calendarRSVPCardDeclineBgColor = UDColor.Name("calendar-rsvp-card-decline-btn-bgcolor")

    static let calendarSettingLightBgColor = UDColor.Name("imtoken-message-bg-location")
    static let calendarEventEditTextPlaceholder = UDColor.Name("calendar-event-edit-text-placeholder")
}

/// 背景： 用于适配同一组件LightDark Mode 下 需要使用不同udtoken的场景
/// 自定义ColorToken格式说明： Light Mode & Dark Mode
/// 用法举例：   UDColor.calendarRSVPCardReactionTagBgColor

extension UDColor {
    static var calendarRSVPCardReactionTagBgColor: UIColor {
        return UDColor.getValueByKey(.calendarRSVPCardReactionTagBgColor) ?? UDColor.udtokenReactionBgGrey & UDColor.udtokenReactionBgGreyFloat
    }
    
    static var calendarRSVPCardacceptBtnBgColor: UIColor {
        return UDColor.getValueByKey(.calendarRSVPCardAcceptBtnBgColor) ?? UIColor.ud.G400 & UIColor.ud.G500
    }
    
    static var calendarRSVPCardDeclineBgColor: UIColor {
        return UDColor.getValueByKey(.calendarRSVPCardDeclineBgColor) ?? UIColor.ud.R400
    }
    
    static var calendarRSVPCardTagBgColor: UIColor {
        return UDColor.getValueByKey(.calendarRSVPCardTagBgColor) ?? UIColor.ud.N900.withAlphaComponent(0.1) & (FG.rsvpStyleOpt ? UDColor.rgb(0xFFFFFF) : UIColor.ud.N600.withAlphaComponent(0.2))
    }

    static var calendarSettingLightBgColor: UIColor {
        return UDColor.getValueByKey(.calendarSettingLightBgColor) ?? UDColor.rgb(0xFAEEC4) & UIColor.ud.Y200
    }
    
    /// 在DarkMode下，placeholder颜色太暗，误认为不可点击，UX要求提亮一下，使用成色值 #999898
    static var calendarEventEditTextPlaceholder: UIColor {
        return UDColor.getValueByKey(.calendarEventEditTextPlaceholder) ?? UIColor.ud.textPlaceholder & UIColor.ud.rgb("#999898")
    }
}
