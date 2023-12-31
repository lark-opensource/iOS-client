//
//  CalendarWidgetEntryView.swift
//  SmartWidgetExtension
//
//  Created by Hayden Wang on 2022/3/9.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import SwiftUI
import WidgetKit
import LarkWidget

struct CalendarWidgetEntryView: View {
    var entry: CalendarEntry

    var body: some View {
        StatusCheckHelper.view(with: entry.authInfo) { CalendarWidgetContentView(model: entry.model) }
    }
}
