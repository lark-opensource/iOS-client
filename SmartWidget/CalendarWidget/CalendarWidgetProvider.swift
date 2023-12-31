//
//  CalendarWidgetProvider.swift
//  Lark
//
//  Created by Hayden Wang on 2022/3/18.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents
import LarkWidget
import LarkLocalizations
import LarkExtensionServices

struct CalendarWidgetProvider: TimelineProvider {

    typealias Entry = CalendarEntry

    @UserDefaultEncoded(key: WidgetDataKeys.calendarData, default: .emptyData)
    private var calendarWidgetData: CalendarWidgetModel

    @UserDefaultEncoded(key: WidgetDataKeys.authInfo, default: .normalInfo(isFeishu: true))
    private var authInfo: WidgetAuthInfo

    func placeholder(in context: Context) -> CalendarEntry {
        return CalendarEntry(date: Date(),
                             authInfo: authInfo,
                             model: .noEventModel)
    }

    func getSnapshot(in context: Context,
                     completion: @escaping (CalendarEntry) -> Void) {
        let snapshotEntry = CalendarEntry(date: Date(),
                                          authInfo: authInfo,
                                          model: calendarWidgetData)
        completion(snapshotEntry)
    }

    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<CalendarEntry>) -> Void) {

        // 更新 Widget 中使用到的 host、language 等信息
        WidgetAuthInfo.updateEnvironmentVariables(with: authInfo)

        let calendarData = calendarWidgetData

        if context.family == .systemSmall {
            // 小尺寸 Widget 刷新逻辑：只展示今天日程，并显示倒计时
            let authInfo = authInfo
            var refreshPoints: [Date] = [Date(), .nextDay]
            for event in calendarData.todayEvents {
                let preOneHour = event.startTime - 3599
                let eventStart = event.startTime + 1
                let eventExpire = event.expireTime + 1
                let eventEnd = event.endTime + 1
                let refreshPointsForEvent = [preOneHour, eventStart, eventExpire, eventEnd].filter {
                    !$0.isInPast && $0.isToday
                }
                refreshPoints.append(contentsOf: refreshPointsForEvent)
            }
            // 去除重复的刷新时间点
            refreshPoints = Array(Set(refreshPoints)).sorted()
            // 用刷新时间组装 timeline
            let entries = refreshPoints.map { refreshDate in
                CalendarEntry(
                    date: refreshDate,
                    authInfo: authInfo,
                    model: calendarData
                )
            }
            // timeline entry 的自动更新，不足以弥补系统计时频率变化的 bug，必须完全 reload timeline
            let nextReloadTime = refreshPoints.first(where: { $0 > Date() }) ?? .nextDay
            let timeline = Timeline(entries: entries, policy: .after(min(nextReloadTime, .nextDay)))
            completion(timeline)
        } else {
            // 中尺寸 Widget 刷新逻辑：空间允许的情况下可展示明天日程，不显示倒计时
            let authInfo = authInfo
            var refreshPoints: [Date] = [Date(), .nextDay]
            for event in calendarData.events {
                let eventExpire = event.expireTime + 1
                let refreshPointsForEvent = [eventExpire].filter {
                    !$0.isInPast && $0.isToday
                }
                refreshPoints.append(contentsOf: refreshPointsForEvent)
            }
            // 去除重复的刷新时间点
            refreshPoints = Array(Set(refreshPoints)).sorted()
            // 用刷新时间组装 timeline
            let entries = refreshPoints.map { refreshDate in
                CalendarEntry(date: refreshDate, authInfo: authInfo, model: calendarData)
            }
            let nextReloadTime = refreshPoints.first(where: { $0 > Date() }) ?? .nextDay
            let timeline = Timeline(entries: entries, policy: .after(min(nextReloadTime, .nextDay)))
            completion(timeline)
        }

        // 写入 displayedCalendarData，表示该数据已经展示
        WidgetDataManager.setWidgetData(calendarData, byKey: WidgetDataKeys.displayedCalendarData)

        // 飞书日历 Widget 展示埋点
        ExtensionTracker.shared.trackTeaEvent(key: "public_widget_view", params: [
            "product_line": "calendar",
            "size": context.family.trackName,
            "is_lock": context.family.lockScreenWidget
        ])
    }
}

struct CalendarEntry: TimelineEntry {
    let date: Date
    let authInfo: WidgetAuthInfo
    let model: CalendarWidgetModel
}
