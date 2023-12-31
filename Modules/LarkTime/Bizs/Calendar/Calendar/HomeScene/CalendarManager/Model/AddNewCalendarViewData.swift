//
//  AddNewCalendarViewData.swift
//  Calendar
//
//  Created by harry zou on 2019/3/25.
//

import Foundation
import CalendarFoundation

final class AddNewCalendarViewData: CalendarManagerModel {
    override var calendarMembersInitiated: Bool {
        get {
            return true
        }
        set {
            _ = newValue
        }
    }
    override var calSummaryRemark: String? {
        get {
            return super.calSummaryRemark
        }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }
}
