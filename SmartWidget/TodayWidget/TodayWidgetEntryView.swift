//
//  TodayWidgetEntryView.swift
//  Lark
//
//  Created by Hayden Wang on 2022/3/9.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import SwiftUI
import WidgetKit
import LarkWidget

struct TodayWidgetEntryView: View {
    var entry: TodayEntry

    var body: some View {
        StatusCheckHelper.view(with: entry.model) { TodayWidgetView(entry.model) }
    }
}

struct TodayWidget_Previews: PreviewProvider {
    static var previews: some View {
        TodayWidgetEntryView(entry: TodayEntry(date: Date(), model: .noEventModel))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
