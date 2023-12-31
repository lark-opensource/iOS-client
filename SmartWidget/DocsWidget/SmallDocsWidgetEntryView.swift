//
//  SmallDocsWidgetEntryView.swift
//  SmartWidgetExtension
//
//  Created by Hayden Wang on 2022/8/11.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import SwiftUI
import WidgetKit
import LarkWidget

struct SmallDocsWidgetEntryView: View {
    var entry: SmallDocsEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        StatusCheckHelper.view(with: entry.authInfo) { SmallDocsWidgetView(item: entry.selectedDoc, image: entry.image) }
    }
}
