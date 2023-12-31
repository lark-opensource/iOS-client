//
//  MediumDocsWidgetEntryView.swift
//  Lark
//
//  Created by Hayden Wang on 2022/8/11.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import SwiftUI
import WidgetKit
import LarkWidget

struct MediumDocsWidgetEntryView: View {
    var entry: MediumDocsEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        StatusCheckHelper.view(with: entry.authInfo) { MediumDocsWidgetView(model: entry.data) }
    }
}
