////
////  MockCalendarEntity.swift
////  CalendarTests
////
////  Created by zhouyuan on 2018/11/21.
////  Copyright © 2018 EE. All rights reserved.
////
//
//import Foundation
//@testable import CalendarFoundation
//@testable import Calendar
//import RustPB
//
//// swiftlint:disable number_separator
//class MockCalendarEntity: CalendarModel {
//    var isLoading: Bool
//
//    var externalAccountName: String
//    func isOwnerOrWriter() -> Bool {
//        return self.selfAccessRole == .owner || self.selfAccessRole == .writer
//    }
//
//    var calendarAccess: CalendarAccess
//
//    var note: String
//
//    var summary: String
//
//    var isDisabled: Bool {
//        return false
//    }
//    var isActive: Bool {
//        return true
//    }
//    var id: String
//    var serverId: String
//    var userId: String
//    var type: MockCalendarEntity.CalendarType
//    var foregroundColor: Int32
//    var backgroundColor: Int32
//    var isVisible: Bool
//    var isPrimary: Bool
//    var selfAccessRole: MockCalendarEntity.AccessRole
//    var selfStatus: MockCalendarEntity.Status
//    var weight: Int32
//    var description: String?
//    var parentCalendarPB: RustPB.Calendar_V1_Calendar?
//    var colormap: MappingColor
//    var calendarPB: RustPB.Calendar_V1_Calendar
//
//    var localizedSummary: String
//    // lark 的主日历
//    func isLarkPrimaryCalendar() -> Bool {
//        return self.isPrimary && self.type != .google
//    }
//
//    func isLarkMainCalendar() -> Bool {
//        return self.type == .primary
//    }
//
//    // lark 的主日历
//    func isAvailablePrimaryCalendar() -> Bool {
//        return self.isPrimary && self.type == .primary
//    }
//
//    func displayName() -> String {
//        return localizedSummary
//    }
//
//    func parentDisplayName() -> String {
//        guard let parentCalendarPB = parentCalendarPB else {
//            return displayName()
//        }
//        if parentCalendarPB.note.isEmpty {
//            return parentCalendarPB.localizedSummary
//        }
//        return parentCalendarPB.note
//    }
//
//    func isGoogleCalendar() -> Bool {
//        return type == .google
//    }
//
//    func calendarBgColor() -> UIColor {
//        return argb(argb: Int64(backgroundColor))
//    }
//
//    func isLocalCalendar() -> Bool {
//        return false
//    }
//
//    func getCalendarPB() -> RustPB.Calendar_V1_Calendar {
//        return calendarPB
//    }
//
//    init() {
//        id = "1591560057517060"
//        serverId = "232"
//        userId = "1591560057517060"
//        type = .primary
//        foregroundColor = -16761187
//        backgroundColor = -9852417
//        localizedSummary = "zhouyuan"
//        isVisible = true
//        isPrimary = true
//        isLoading = false
//        selfAccessRole = .owner
//        selfStatus = .accepted
//        weight = 100
//        description = "112"
//        var mappingColor = MappingColor()
//        mappingColor.backgroundColor = -9852417
//        mappingColor.foregroundColor = -16761187
//        mappingColor.eventCardColor = -10510865
//        mappingColor.eventColorIndex = "6"
//        colormap = mappingColor
//        calendarPB = RustPB.Calendar_V1_Calendar()
//        calendarAccess = .freeBusy
//        note = "sdf"
//        summary = "dfg"
//        externalAccountName = ""
//    }
//
//}
