//
//  UtilityWidget.swift
//  SmartWidgetExtension
//
//  Created by Hayden Wang on 2022/4/7.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import SwiftUI
import WidgetKit
import LarkWidget

struct UtilityWidget: Widget {
    let kind: String = LarkWidgetKind.utilityWidget

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: LarkUtilityConfigurationIntent.self, provider: UtilityWidgetProvider()) { entry in
            UtilityWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(BundleI18n.LarkWidget.Lark_Widget_OftenUsedFunctions_Title)
        .description(BundleI18n.LarkWidget.Lark_Widget_iOS_SelectFeatureToDisplay_Desc)
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabledIfAvailable()
    }
}
