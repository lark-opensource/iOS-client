//
//  TodayWidgetProvider.swift
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

struct TodayWidgetProvider: TimelineProvider {

    typealias Entry = TodayEntry

    @UserDefaultEncoded(key: WidgetDataKeys.legacyData, default: .notLoginData)
    private var widgetData: WidgetData

    @UserDefaultEncoded(key: WidgetDataKeys.authInfo, default: .normalInfo(isFeishu: true))
    private var authInfo: WidgetAuthInfo

    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: Date(),
                   model: .noEventModel)
    }

    func getSnapshot(in context: Context,
                     completion: @escaping (TodayEntry) -> Void) {

        let widgetData = widgetData

        // 未登录状态
        if !widgetData.isLogin {
            completion(TodayEntry(date: Date(), model: .notLoginModel))
            return
        }

        let todayEvents = widgetData.todayEvents
        if todayEvents.isEmpty {
            let snapshotEntry = TodayEntry(date: Date(), model: .noEventModel)
            completion(snapshotEntry)
        } else {
            let model = TodayWidgetModel(isMinimumMode: false,
                                         isLogin: true,
                                         hasEvent: true,
                                         event: todayEvents[0],
                                         actions: widgetData.actions)
            let snapshotEntry = TodayEntry(date: Date(), model: model)
            completion(snapshotEntry)
        }
    }

    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<TodayEntry>) -> Void) {

        // 更新 Widget 中使用到的 host、language 等信息
        WidgetAuthInfo.updateEnvironmentVariables(with: authInfo)

        let widgetData = widgetData

        // 精简模式
        if widgetData.isMinimumMode {
            let timeline = Timeline(
                entries: [TodayEntry(date: Date(), model: .minimumModeModel)],
                policy: .never
            )
            completion(timeline)
            return
        }

        // 未登录状态
        if !widgetData.isLogin {
            let timeline = Timeline(
                entries: [TodayEntry(date: Date(), model: .notLoginModel)],
                policy: .never
            )
            completion(timeline)
            return
        }

        // 筛选出今日的有效日程
        let todayEvents = widgetData.todayEvents
        // 将日程组装成 entries
        var entries: [TodayEntry] = []
        // 新 timeline entry 的刷新时间（旧日程过期时间即为刷新时间）
        var previousExpireTime = Date()
        let eventsCount = todayEvents.count
        for index in 0..<eventsCount {
            let model = TodayWidgetModel(isMinimumMode: false,
                                         isLogin: true,
                                         hasEvent: true,
                                         event: todayEvents[index],
                                         actions: widgetData.actions)
            entries.append(TodayEntry(date: previousExpireTime, model: model))
            if index == todayEvents.count - 1 {
                // 如果是最后一条日程，刷新时间设为日程结束
                previousExpireTime = todayEvents[index].endTime
            } else {
                // 如果不是最后一条日程，刷新时间为日程开始后 10 分钟
                previousExpireTime = todayEvents[index].expireTime
            }
        }
        // 最后添加一个没有事件的 entry，所有日程结束后显示”无日程“
        entries.append(TodayEntry(date: previousExpireTime, model: .noEventModel))
        // 组装 timeline，并将刷新 timeline 时间定为次日早上
        let timeline = Timeline(entries: entries, policy: .after(.nextDay))
        completion(timeline)
    }
}

struct TodayEntry: TimelineEntry {
    let date: Date
    let model: TodayWidgetModel
}
