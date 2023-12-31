//
//  CalendarComponents.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/3/7.
//

import Foundation
import SwiftUI
import WidgetKit
import LarkTimeFormatUtils

@available(iOS 14.0, *)
struct AppIconView: View {

    var body: some View {
        Image("widget_logo")
            .resizable()
            .frame(width: 24, height: 24)
    }
}

@available(iOS 14.0, *)
struct CalendarDateView: View {

    var date: Date

    var body: some View {
        VStack {
            Text(getWeekdayByDateFormatter())
                .font(.system(size: 12))
                .foregroundColor(.blue)
            Text(getDayOfMonth())
                .font(.system(size: 34))
                .fontWeight(.light)
        }
    }

    private func getDayOfMonth() -> String {
        var calendar = Calendar.current
        calendar.locale = WidgetI18n.language.locale
        let components = calendar.dateComponents([.day], from: date)
        return "\(components.day ?? 1)"
    }

    /*
    // 使用系统日历的方法获取当前 weekday 名称，如 “星期日”
    private func getWeekdayByCalendar() -> String {
        // setup calendar
        var calendar = Calendar.current
        calendar.locale = WidgetI18n.language.locale
        // get day of week
        let components = calendar.dateComponents([.weekday], from: date)
        let weekday = components.weekday ?? 1
        // get localized weekday name
        let dayIndex = ((weekday - 1) + (calendar.firstWeekday - 1)) % 7
        return calendar.weekdaySymbols[dayIndex]
    }
     */

    // 使用 dateFormatter 方法获取当前 weekday 名称，如 “星期日”
    private func getWeekdayByDateFormatter() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        dateFormatter.locale = WidgetI18n.language.locale
        return dateFormatter.string(from: date).capitalized
    }
}

@available(iOS 14.0, *)
struct CalendarEventView: View {

    @Environment(\.widgetFamily) var family

    var title: String
    var time: String
    var place: String?
    var url: URL?
    var color: Color
    var event: CalendarEvent
    var useCompactLayout: Bool
    var numberOfLinesForTitle: Int = 1

    init(_ event: CalendarEvent,
         color: Color = .blue,
         useCompactLayout: Bool = false) {
        self.event = event
        self.title = event.name
        self.time = event.subtitle
        self.place = event.description
        self.color = color
        self.useCompactLayout = useCompactLayout
        // 将埋点参数加入到 URL 中
        self.url = WidgetTrackingTool.createURL(event.appLink, trackParams: [
            "click": "cal_click",
            "size": family.trackName,
            "is_lock": family.lockScreenWidget,
            "target": "cal_event_detail_view"
        ])
    }

    var body: some View {
        if let url = url {
            Link(destination: url) {
                contentView
            }
        } else {
            contentView
        }
    }

    private var contentView: some View {
        HStack(spacing: 6) {
            // 左侧竖线
            RoundedRectangle(cornerRadius: 1.75)
                .frame(width: 3.5)
                .themeColor(color, widgetAccent: true)
                .padding(.vertical, 2)
            // 右侧内容
            VStack(alignment: .leading, spacing: 2) {
                Text(event.name)
                    .font(.system(size: useCompactLayout ? 11 : 12))
                    .fontWeight(.medium)
                    .themeColor(WidgetColor.text, widgetAccent: true)
                    .lineLimit(family == .systemSmall ? 2 : 1)
                if !event.isAllDay {
                    Text(event.startTime...event.endTime)
                        .font(.system(size: useCompactLayout ? 10 : 12))
                        .foregroundColor(WidgetColor.text)
                        .lineLimit(1)
                }
                if let place = event.eventPlace {
                    Text(place)
                        .font(.system(size: useCompactLayout ? 10 : 12))
                        .foregroundColor(WidgetColor.text)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }.fixedSize(horizontal: false, vertical: true)
    }
}

@available(iOSApplicationExtension 14, *)
extension View {

    @ViewBuilder
    func themeColor(_ color: Color? = nil, widgetAccent: Bool = false) -> some View {
        self.foregroundColor(color)
        /*
        if #available(iOS 16, *), widgetAccent {
            self.widgetAccentable()
        } else {
            self.foregroundColor(color)
        }
         */
    }
}
