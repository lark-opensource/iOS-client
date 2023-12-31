//
//  CalendarMiddlewareHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/9.
//

import Foundation
import LarkContainer
import LarkNavigator
import EENavigator
import LKCommonsTracker
import LarkTab
import UIKit
import LarkUIKit

final class CalendarMiddlewareHandler: UserMiddlewareHandler {

    func handle(req: EENavigator.Request, res: EENavigator.Response) throws {
        // 进入日历业务前，检查calendar是否被初始化。日历首页除外
        if res.request.url.absoluteString.contains("/client/calendar") && res.request.url != Tab.calendar.url {
            let resolver = self.userResolver
            let calendarManager = try resolver.resolve(assert: CalendarManager.self)
            let viewType: String
            if calendarManager.isRustCalendarEmpty && !res.request.url.absoluteString.contains("/client/calendar/setting") {
                calendarManager.updateRustCalendar()
                let vc = CalendarErrorViewController()
                res.end(resource: vc)
                viewType = "error_view"
            } else {
                viewType = "normal_view"
            }
            // https://slardar.bytedance.net/node/app_detail/?aid=1161&os=iOS&region=cn&lang=zh#/event/list/detail_v2/cal_navi_landing_page?params=%7B%22start_time%22%3A1629806700%2C%22end_time%22%3A1629900300%2C%22granularity%22%3A86400%2C%22filters_conditions%22%3A%7B%22type%22%3A%22and%22%2C%22sub_conditions%22%3A%5B%5D%7D%2C%22pgno%22%3A1%2C%22pgsz%22%3A10%7D
            Tracker.post(SlardarEvent(
                name: "cal_navi_landing_page",
                metric: [:],
                category: ["view_type": viewType],
                extra: [:]
            ))
        }
    }

}
