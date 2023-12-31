//
//  UIStyle.swift
//  Calendar
//
//  Created by Hongbin Liang on 6/6/23.
//

import Foundation

// 日历 详情页&编辑页
struct CalendarUI {
    static let contentHeight = 44.0
    static let statusBarHeight: CGFloat = UIApplication.shared.statusBarFrame.height
    /// 左上角图标的Size
    static let closeIconSize: CGSize = CGSize(width: 24, height: 24)
    /// 左上角图标的y
    static let closeIconY = statusBarHeight + (contentHeight - closeIconSize.height) * 0.5
}
