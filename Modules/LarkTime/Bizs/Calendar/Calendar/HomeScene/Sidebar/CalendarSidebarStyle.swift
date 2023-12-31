//
//  CalendarSettingStyle.swift
//  Calendar
//
//  Created by linlin on 2018/1/17.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import CalendarFoundation
final class CalendarSidebarStyle {
    static let systemStatusBarHeight: CGFloat = 20
    static let systemNavBarHeight: CGFloat = 44

    static let backButtonHeight: CGFloat = 24
    static let backButtonLeftOffset: CGFloat = 12
    static let backButtonTopOffset: CGFloat = 10

    static let lineBgColor = UIColor.ud.lineBorderCard
    static let lineHeight: CGFloat = 0.5
    static let lineTopOffset: CGFloat = 59.5

    static let headerViewLabelHeight: CGFloat = 36.5
    static let headerViewLabelWidth: CGFloat = 92
    static let headerViewLabelLeftOffset: CGFloat = 16
    static let headerViewLabelTopOffset: CGFloat = 12.5
    static let headerViewLabelFont = CalendarExtension.semiboldFont(ofSize: 26)

    static let sectionViewTop: CGFloat = 12
    static let sectionViewLeft: CGFloat = 20
    static let sectionViewHeight: CGFloat = 13
    static let labelTextFont = CalendarExtension.mediumFont(ofSize: 16)

    static let tableViewTop: CGFloat = lineTopOffset + lineHeight
    static let tableViewSectionHeight: CGFloat = 46

    static let headerViewHeight: CGFloat = 58.0

    static let sidebarWidth: CGFloat = 60.0

    final class FilterItemCell {

        static let cellHeight: CGFloat = 44
        static let checkboxLeft: CGFloat = 16
        static let checkboxTop: CGFloat = 13
        static let checkboxSize: CGFloat = 19

        static let labelLeftOffset: CGFloat = 8
        static let labelRight: CGFloat = -16
        static let labelTextFont = CalendarExtension.regularFont(ofSize: 16)
        static let labelTextColor = UIColor.ud.textTitle

        static let googleLogoWidth = 12
        static let googleLogoLeftOffset = 5
    }

}
