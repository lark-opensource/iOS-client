//
//  RectangularCalendarWidgetView.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/9/19.
//

import Foundation
import SwiftUI
import WidgetKit

@available(iOS 16.0, *)
public struct RectangularCalendarWidgetView: View {

    @Environment(\.widgetFamily) var family

    public var model: CalendarWidgetModel

    let currentEvent: CalendarEvent?

    public init(model: CalendarWidgetModel) {
        self.model = model
        self.currentEvent = model.todayEvents.first
    }

    public var body: some View {
        ZStack {
            if let event = currentEvent {
                // 显示最新日程
                RectangularCalendarEventView(event)
            } else {
                // 显示暂无日程文案
                Text(BundleI18n.LarkWidget.Lark_Core_NoEventsToday.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        .widgetURL(eventURL)
    }

    private var eventURL: URL? {
        if let eventLink = currentEvent?.appLink {
            return WidgetTrackingTool.createURL(eventLink, trackParams: [
                "click": "cal_click",
                "size": family.trackName,
                "is_lock": family.lockScreenWidget,
                "target": "cal_event_detail_view"
            ])
        } else {
            return WidgetTrackingTool.createURL(WidgetLink.calendarTab, trackParams: [
                "click": "cal_click",
                "size": family.trackName,
                "is_lock": family.lockScreenWidget,
                "target": "none"
            ])
        }
    }
}

@available(iOS 16.0, *)
struct RectangularCalendarEventView: View {

    @Environment(\.widgetFamily) var family
    var event: CalendarEvent
    var url: URL?

    init(_ event: CalendarEvent) {
        self.event = event
    }

    var body: some View {
        contentView
    }
    
    /// 当日程没有日期或地点时，标题可显示多行
    var numberOfLineForTitle: Int {
        var numberOfLines = 1
        if event.isAllDay { numberOfLines += 1 }
        if event.eventPlace == nil { numberOfLines += 1 }
        return numberOfLines
    }

    private var contentView: some View {
        HStack(spacing: 6) {
            // 左侧竖线
            RoundedRectangle(cornerRadius: 1.75)
                .frame(width: 3.5)
                .widgetAccentable()
                .padding(.vertical, 2)
            // 右侧内容
            VStack(alignment: .leading) {
                // 名称
                Text(event.name)
                    .font(.headline)
                    .widgetAccentable()
                    .lineLimit(numberOfLineForTitle)
                // 时间
                if !event.isAllDay {
                    Text(event.startTime...event.endTime)
                        .lineLimit(1)
                }
                // 地点
                if let place = event.eventPlace {
                    Text(place)
                        .opacity(0.7)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }.fixedSize(horizontal: false, vertical: true)
    }
}
