//
//  SmallDocsWidget.swift
//  SmartWidgetExtension
//
//  Created by Hayden Wang on 2022/8/11.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import SwiftUI
import WidgetKit
import LarkWidget

struct SmallDocsWidget: Widget {
    let kind: String = LarkWidgetKind.smallDocsWidget

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: SmallDocsConfigurationIntent.self, provider: SmallDocsWidgetProvider()) { entry in
            SmallDocsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(BundleI18n.LarkWidget.Lark_DocsWidget_Docs_Text)
        .description(BundleI18n.LarkWidget.Lark_DocsWidget_Docs_SelectDocsToDisplayOnHomeScreen_Text)
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabledIfAvailable()
    }
}
