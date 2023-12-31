//
//  MonitorService.swift
//  CalendarRichTextEditor
//
//  Created by 张威 on 2020/7/23.
//

import Foundation
import LKCommonsTracker

final class MonitorService: JSServiceHandler {
    var handleServices: [JSService] {
        return [.rtUtilMonitor]
    }

    func handle(params: [String: Any], serviceName: String) {
        Tracker.post(SlardarEvent(name: "cal_docs_js_error", metric: [:], category: [:], extra: params))
    }
}
