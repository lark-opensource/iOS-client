//
//  TodayWidget.swift
//  SmartWidgetExtension
//
//  Created by Hayden Wang on 2022/4/7.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import SwiftUI
import WidgetKit
import LarkWidget

struct TodayWidget: Widget {
    let kind: String = LarkWidgetKind.todayWidget

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind,
                            provider: TodayWidgetProvider()) { entry in
            TodayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(BundleI18n.LarkWidget.Lark_SmartWidget_Name())
        .description(BundleI18n.LarkWidget.Lark_SmartWidget_Desc)
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabledIfAvailable()
    }
}
