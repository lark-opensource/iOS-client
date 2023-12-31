//
//  UtilityWidgetEntryView.swift
//  SmartWidgetExtension
//
//  Created by Hayden Wang on 2022/4/7.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import SwiftUI
import WidgetKit
import LarkWidget

struct UtilityWidgetEntryView: View {
    var entry: UtilityWidgetProvider.Entry

    var body: some View {
        StatusCheckHelper.view(with: entry.authInfo) {
            UtilityWidgetContentView(
                authInfo: entry.authInfo,
                data: entry.data,
                addedTools: entry.addedTools
            )
        }
    }
}
