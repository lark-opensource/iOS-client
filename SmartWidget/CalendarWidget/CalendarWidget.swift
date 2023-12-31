//
//  CalendarWidget.swift
//  SmartWidgetExtension
//
//  Created by Hayden Wang on 2022/4/7.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import SwiftUI
import WidgetKit
import LarkWidget

struct CalendarWidget: Widget {
    let kind: String = LarkWidgetKind.calendarWidget

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind,
                            provider: CalendarWidgetProvider()) { entry in
            CalendarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(BundleI18n.LarkWidget.Lark_SmartWidget_Name())
        .description(BundleI18n.LarkWidget.Lark_SmartWidget_Desc)
        .supportedFamilies(supportedWidgetFamilies)
        .contentMarginsDisabledIfAvailable()
    }

    private var supportedWidgetFamilies: [WidgetFamily] {
        var families: [WidgetFamily] = [.systemSmall, .systemMedium]
        if #available(iOSApplicationExtension 16.0, *) {
            families.append(.accessoryRectangular)
            families.append(.accessoryCircular)
        }
        return families
    }
}
