//
//  TodoWidgetEntryView.swift
//  Lark
//
//  Created by Hayden Wang on 2022/5/9.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import SwiftUI
import WidgetKit
import LarkWidget

struct TodoWidgetEntryView: View {
    var entry: TodoEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        StatusCheckHelper.view(with: entry.authInfo) { TodoWidgetContentView(model: entry.model) }
    }
}
