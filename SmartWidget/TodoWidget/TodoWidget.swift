//
//  TodoWidget.swift
//  Lark
//
//  Created by Hayden Wang on 2022/5/9.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import SwiftUI
import WidgetKit
import LarkWidget

struct TodoWidget: Widget {
    let kind: String = LarkWidgetKind.todoWidget

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind,
                            provider: TodoWidgetProvider()) { entry in
            TodoWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(BundleI18n.LarkWidget.Lark_TasksWidget_TaskCenter_Name)
        .description(BundleI18n.LarkWidget.Lark_TasksWidget_TaskCenter_QuickAccess_Desc)
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabledIfAvailable()
    }
}
