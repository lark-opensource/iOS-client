//
//  DaySceneAction.swift
//  Calendar
//
//  Created by 张威 on 2020/7/16.
//  Copyright © 2020 ByteDance. All rights reserved.
//

import UIKit

/// DayScene - StoreAction

enum DaySceneAction {
    // 适配全天日程的 visible height
    case adjustAllDayVisibleHeight(height: CGFloat)

    // 新建日程
    case createEvent(startDate: Date, endDate: Date)

    // 展示日程详情
    case showDetail(instance: BlockDataProtocol)
    
    // 展示时区弹窗
    case showTimeZonePopup

    // 滚动到当前时刻
    case scrollToNow

    // 滚动到目标 day
    case scrollToDay(JulianDay)

    // 滚动到目标日期，具体到秒
    case scrollToDate(Date)

    // 清除日程块编辑相关内容
    case clearEditingContext

    // 冷启动结束
    case didFinishColdLaunch
    
    // 可点击icon被点击
    case tapIconTapped(instance: BlockDataProtocol, isSelected: Bool)
}

extension DaySceneAction: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .adjustAllDayVisibleHeight(let height):
            return "adjustAllDayVisibleHeight. height: \(height)"
        case .createEvent(let startDate, let endDate):
            return "createEvent. startDate: \(startDate), endDate: \(endDate)"
        case .showDetail:
            return "showInstanceDetail"
        case .showTimeZonePopup:
            return "showTimeZonePopup"
        case .scrollToNow:
            return "scrollToNow"
        case .scrollToDay(let julianDay):
            return "scrollToDay. julianDay: \(julianDay)"
        case .clearEditingContext:
            return "clearEditingContext"
        case .didFinishColdLaunch:
            return "didFinishColdLaunch"
        case .scrollToDate(let date):
            return "scrollToDate. date: \(date)"
        case .tapIconTapped:
            return "tapIconTapped"
        }
    }
}
