//
//  MediumCalendarWidgetView.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/3/7.
//

import Foundation
import SwiftUI
import WidgetKit

@available(iOS 14.0, *)
public struct MediumCalendarWidgetView: View {

    public var model: CalendarWidgetModel
    var todayEventsCount: Int
    let todayEvents: [CalendarEvent]
    let tomorrowEvents: [CalendarEvent]
    // 内容比较紧凑的情况下，将布局调小
    var useCompactLayout: Bool = false

    public init(model: CalendarWidgetModel) {
        self.model = model
        // 按照 PRD 规则，计算将要展示的日程
        // 规则：https://bytedance.feishu.cn/docx/doxcnLdOfAbNmGqlJsza3uQQe8f
        //  - 当用户当天的日程不满3个，其其中有一个没有用会议室地址时，展示明天的日程
        //  - 按照最高条数限制，如果超过限制，则不展示明天会议室的地址，仅展示明天会议的标题和时间
        //  - 当某一天的日程只能展示标题，无法展示时间时，则不展示该日程
        let todayEvents = Array(model.todayEvents.prefix(3))
        var tomorrowEvents = Array(model.tomorrowEvents.prefix(3 - todayEvents.count))
        // 超过 1 条今日日程有地点时，明日日程都不显示地址
        if todayEvents.compactMap({ $0.eventPlace }).count > 1 {
            tomorrowEvents = tomorrowEvents.map { $0.removePlace() }
        }
        // 有明日日程，或者今日 3 条日程都有会议室时，使用紧凑布局
        if todayEvents.compactMap({ $0.eventPlace }).count == 3 {
            useCompactLayout = true
        }
        if !tomorrowEvents.isEmpty, !(todayEvents + tomorrowEvents).compactMap({ $0.eventPlace }).isEmpty {
            useCompactLayout = true
        }
        // 确定将要显示的今日日程和明日日程
        self.todayEvents = todayEvents
        self.tomorrowEvents = tomorrowEvents
        self.todayEventsCount = model.todayEvents.count
    }

    public var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                CalendarDateView(date: Date())
                Spacer()
                if todayEventsCount > 3 {
                    Text(BundleI18n.LarkWidget.Lark_Core_NumLeft(todayEventsCount - 3, lang: WidgetI18n.language))
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundColor(WidgetColor.secondaryText)
                } else {
                    AppIconView()
                }
            }
            .frame(width: 74, alignment: .leading)

            // 日程
            if hasEvent {
                VStack {
                    VStack(alignment: .leading, spacing: useCompactLayout ? 5 : 8) {
                        // 今日日程
                        ForEach(0..<todayEvents.count, id: \.self) { index in
                            CalendarEventView(
                                todayEvents[index],
                                color: colorPalette[index % colorPalette.count],
                                useCompactLayout: useCompactLayout
                            )
                        }
                        // 明日日程
                        if !tomorrowEvents.isEmpty {
                            Text(BundleI18n.LarkWidget.Lark_Widget_Calendar_Tomorrow_Title)
                                .lineLimit(1)
                                .font(.system(size: useCompactLayout ? 11 : 12))
                                .foregroundColor(WidgetColor.secondaryText)
                            ForEach(0..<tomorrowEvents.count, id: \.self) { index in
                                CalendarEventView(
                                    tomorrowEvents[index],
                                    color: colorPalette[todayEvents.count + index % colorPalette.count],
                                    useCompactLayout: useCompactLayout
                                )
                            }
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            } else {
                Spacer()
                VStack {
                    Image("empty_calender")
                        .resizable()
                        .frame(width: 74, height: 74)
                    Text(BundleI18n.LarkWidget.Lark_Core_NoEventsToday)
                        .font(.system(size: 12))
                        .foregroundColor(WidgetColor.secondaryText)
                }
                Spacer()
            }
        }
        .padding()
        .widgetBackground(WidgetColor.background)
        .widgetURL(URL(string: WidgetLink.calendarTab))
    }

    public var colorPalette: [Color] = [.green, .red, .purple]

    var hasEvent: Bool {
        !(todayEvents.isEmpty && tomorrowEvents.isEmpty)
    }
}

@available(iOS 14.0, *)
public struct MediumCalendarWidgetView_Previews: PreviewProvider {
    public static var previews: some View {
        MediumCalendarWidgetView(model: .multiEventModel)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
