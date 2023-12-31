//
//  SmallCalendarWidgetView.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/3/7.
//

import Foundation
import SwiftUI
import WidgetKit

@available(iOS 14.0, *)
public struct SmallCalendarWidgetView: View {

    @Environment(\.widgetFamily) var family

    public var model: CalendarWidgetModel

    let currentEvent: CalendarEvent?

    public init(model: CalendarWidgetModel) {
        self.model = model
        self.currentEvent = model.todayEvents.first
    }

    public var body: some View {
        GeometryReader { proxy in
            VStack {
                HStack(alignment: .top) {
                    CalendarDateView(date: Date())
                    Spacer()
                    AppIconView()
                }

                Spacer()

                if let currentEvent = currentEvent {
                    VStack(alignment: .leading, spacing: 6) {
                        // 没有会议室，或者标题不是双行（即 Y 轴空间足够的情况下），显示最近日程的倒计时
                        // NOTE: 32 是 Widget 左右边距，13.5 是玄学数字 (9.5+4?)，SwiftUI 里无法使用 UIKit 的思维计算日程名是单行还是双行
                        if currentEvent.eventPlace == nil ||
                            currentEvent.name.getWidth(font: .systemFont(ofSize: 12)) < proxy.size.width - 13.5 - 32 {
                            if currentEvent.isStarted {
                                Text(BundleI18n.LarkWidget.Lark_Widget_Calendar_Ongoing_Title)
                                    .lineLimit(1)
                                    .font(.system(size: 12))
                                    .foregroundColor(WidgetColor.secondaryText)
                            } else {
                                Text(currentEvent.startTime, style: .relative)
                                    .lineLimit(1)
                                    .font(.system(size: 12))
                                    .foregroundColor(WidgetColor.secondaryText)
                            }
                        }
                        CalendarEventView(currentEvent)
                    }
                } else {
                    Text(BundleI18n.LarkWidget.Lark_Core_NoEventsToday)
                        .font(.system(size: 12))
                        .foregroundColor(WidgetColor.secondaryText)
                    Spacer()
                }
            }
            .padding(.all, 16)
            .widgetBackground(WidgetColor.background)
            .widgetURL(eventURL)
        }
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

@available(iOS 14.0, *)
public struct SmallCalendarWidgetView_Previews: PreviewProvider {
    public static var previews: some View {
        SmallCalendarWidgetView(model: .multiEventModel)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
