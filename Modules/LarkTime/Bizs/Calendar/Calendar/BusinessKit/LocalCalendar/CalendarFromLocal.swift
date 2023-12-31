//
//  CalendarFromLocal.swift
//  Calendar
//
//  Created by jiayi zou on 2018/9/11.
//  Copyright © 2018 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation
import EventKit
import RustPB

//eventIdentifier
//startDate
//endDate
//occurrenceDate
//calendar
//title
//EKEvent需检查上述几个字段部位空

final class CalendarFromLocal: CalendarModel {
    func upgradeCalendarSyncInfo(info: Rust.CalendarSyncInfo) {
        assertionFailureLog()
    }

    func isLoading(eventViewStartTime: Int64, eventViewEndTime: Int64) -> Bool {
        return false
    }

    var ekType: EKCalendarType {
        return localCalendar.type
    }

    var source: EKSource! {
        return localCalendar.source
    }

    var externalAccountValid: Bool {
        return true
    }

    var externalAccountName: String {
        return ""
    }

    var isDisabled: Bool {
        return false
    }

    var needApproval: Bool {
        return false
    }

    var hasSubscribed: Bool {
        get { return true }
        set { _ = newValue}
    }

    var summary: String {
        get { return localCalendar.title }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }

    var avatarKey: String {
        get { return "" }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }

    var avatar: UIImage? {
        get { return nil }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }

    var localizedSummary: String {
        get {
            return localCalendar.title
        }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }

    var note: String {
        get {
            return localCalendar.title
        }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }

    var calendarAccess: CalendarAccess {
        get {
            return .privacy
        }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }

    var isActive: Bool {
        return true
    }

    private var localCalendar: EKCalendar

    var colorIndex: ColorIndex {
        get {
            if let color = localCalendar.cgColor { return LocalCalHelper.getColor(color: color) }
            assertionFailureLog()
            return .carmine
        }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }

    var id: String {
        return localCalendar.calendarIdentifier
    }

    var serverId: String {
        set {
            assertionFailure("can't set local calenderID")
        }
        get {
            return localCalendar.calendarIdentifier
        }
    }

    var userId: String {
        //assertionFailureLog("you should not use local calendar user id")
        get { return "you should not use local calendar user id" }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }

    var type: CalendarFromLocal.CalendarType {
        return .unknownType
    }

    var backgroundColor: Int32 {
        get {
            assertionFailureLog()
            return -1
        }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }


    //不使用这个字段而是使用LocalCalendarManager的接口来设置是否可见
    var isVisible: Bool {
        get {
            return LocalCalendarManager.isVisible(localCal: localCalendar)
        }
        set {
            assertionFailureLog()
            _ = newValue
        }
    }

    var isPrimary: Bool {
        return false
    }

    var selfAccessRole: CalendarFromLocal.AccessRole {
        return localCalendar.allowsContentModifications ? .writer : .unknownAccessRole
    }

    var selfStatus: CalendarFromLocal.Status {
        return .default
    }

    var weight: Int32 {
        return 0
    }

    var description: String?

    var parentCalendarPB: RustPB.Calendar_V1_Calendar? {
        get {
            return nil
        }
        set {
            assertionFailureLog("you must not modify local calendar parentCalendarPB")
            _ = newValue
        }
    }

    var editAuthInfo: EditAuthInfo {
        return RustPB.Calendar_V1_Calendar.CalendarEditAuthInfo()
    }

    var shareOptions: ShareOptions {
        set {
            assertionFailureLog("you must not modify local calendar parentCalendarPB")
            _ = newValue
        }
        get {
            return ShareOptions()
        }
    }

    func isOwnerOrWriter() -> Bool {
        return self.selfAccessRole == .owner || self.selfAccessRole == .writer
    }
    
    func canRead() -> Bool {
        return self.selfAccessRole == .owner || self.selfAccessRole == .writer || self.selfAccessRole == .reader
    }

    func isLarkMainCalendar() -> Bool {
        return false
    }

    func isLarkPrimaryCalendar() -> Bool {
        return false
    }

    func isAvailablePrimaryCalendar() -> Bool {
        return false
    }

    func displayName() -> String {
        return localCalendar.title
    }

    func parentDisplayName() -> String {
        return ""
    }

    func isGoogleCalendar() -> Bool {
        return false
    }

    func isExchangeCalendar() -> Bool {
        return false
    }

    init(localCalendar: EKCalendar) {
        self.localCalendar = localCalendar
    }

    func isLocalCalendar() -> Bool {
        return true
    }
}
