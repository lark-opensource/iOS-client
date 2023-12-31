//
//  SmartWidgetBundle.swift
//  Lark
//
//  Created by Hayden Wang on 2022/3/9.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import SwiftUI
import WidgetKit

@main
struct SmartWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalendarWidget()
        TodoWidget()
        DocsWidgetBundle().body
        MoreWidgetsBundle().body
        TodayWidget()
    }
}

/// NOTE：WidgetBundle body 内部有 5 个数量限制，所以采用此方法解决
struct DocsWidgetBundle: WidgetBundle {
    var body: some Widget {
        SmallDocsWidget()
        MediumDocsWidget()
    }
}

struct MoreWidgetsBundle: WidgetBundle {
    var body: some Widget {
        UtilityWidget()
#if swift(>=5.7.1)
        if #available(iOSApplicationExtension 16.1, *) {
            ByteViewMeetingWidget()
        }
#endif
    }
}
