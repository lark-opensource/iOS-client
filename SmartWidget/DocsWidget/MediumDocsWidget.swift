//
//  MediumDocsWidget.swift
//  Lark
//
//  Created by Hayden Wang on 2022/8/11.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import SwiftUI
import WidgetKit
import LarkWidget

struct MediumDocsWidget: Widget {
    let kind: String = LarkWidgetKind.mediumDocsWidget

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: MediumDocsConfigurationIntent.self, provider: MediumDocsWidgetProvider()) { entry in
            MediumDocsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(BundleI18n.LarkWidget.Lark_DocsWidget_Docs_Text)
        .description(BundleI18n.LarkWidget.Lark_DocsWidget_Docs_SelectDocsToDisplayOnHomeScreen_Text)
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabledIfAvailable()
    }
}
