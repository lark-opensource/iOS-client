//
//  CircularCalendarWidgetView.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/9/20.
//

import Foundation
import SwiftUI
import WidgetKit

@available(iOS 14.0, *)
public struct CircularCalendarWidgetView: View {

    @Environment(\.widgetFamily) var family

    public var model: CalendarWidgetModel

    let currentEvent: CalendarEvent?

    public init(model: CalendarWidgetModel) {
        self.model = model
        self.currentEvent = model.todayEvents.first
    }

    public var body: some View {
        if #available(iOSApplicationExtension 16.0, *) {
            ZStack {
                AccessoryWidgetBackground()
                HStack {
                    Image(systemName: "calendar")
                        .resizable()
                        .frame(width: 12, height: 12)
                    Text(model.todayEvents.count > 99 ? "99+" : "\(model.todayEvents.count)")
                        .font(.headline)
                        .widgetAccentable()
                }
            }
            .widgetURL(eventURL)
        } else {
            // Fallback on earlier versions
            Text("not supported")
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
public struct CircularCalendarWidgetView_Previews: PreviewProvider {
    public static var previews: some View {
        CircularCalendarWidgetView(model: .multiEventModel)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
