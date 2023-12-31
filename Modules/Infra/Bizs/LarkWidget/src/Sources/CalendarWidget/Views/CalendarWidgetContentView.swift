//
//  CalendarWidgetContentView.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/5/30.
//

import Foundation
import SwiftUI
import WidgetKit

@available(iOS 14.0, *)
public struct CalendarWidgetContentView: View {

    var model: CalendarWidgetModel

    @Environment(\.widgetFamily) var family

    public init(model: CalendarWidgetModel) {
        self.model = model
    }

    public var body: some View {
        Group {
            if #available(iOSApplicationExtension 16.0, *) {
                switch family {
                case .systemSmall:
                    SmallCalendarWidgetView(model: model)
                        .widgetBackground(WidgetColor.background)
                case .systemMedium:
                    MediumCalendarWidgetView(model: model)
                        .widgetBackground(WidgetColor.background)
                case .accessoryRectangular:
                    RectangularCalendarWidgetView(model: model)
                case .accessoryCircular:
                    CircularCalendarWidgetView(model: model)
                default:
                    Text("Not supported")
                }
            } else {
                switch family {
                case .systemSmall:
                    SmallCalendarWidgetView(model: model)
                        .widgetBackground(WidgetColor.background)
                case .systemMedium:
                    MediumCalendarWidgetView(model: model)
                        .widgetBackground(WidgetColor.background)
                default:
                    Text("Not supported")
                }
            }
        }
    }
}
