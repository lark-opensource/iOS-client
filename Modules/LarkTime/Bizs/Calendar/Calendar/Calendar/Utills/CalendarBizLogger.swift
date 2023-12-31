//
//  CalendarLogger.swift
//  Calendar
//
//  Created by Hongbin Liang on 4/23/23.
//

import Foundation
import LKCommonsLogging

struct CalendarBiz {
    static let detailLogger = Logger.log(Calendar.self, category: "calendar.calendar_detail")
    static let shareLogger = Logger.log(Calendar.self, category: "calendar.calendar_share")
    static let editLogger = Logger.log(Calendar.self, category: "calendar.calendar_edit")
}
