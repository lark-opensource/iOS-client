//
//  CalendarSidebarController.swift
//  Calendar
//
//  Created by zhouyuan on 2018/9/19.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import CalendarFoundation
import LarkButton
import SnapKit
import RxSwift
import LarkActionSheet
import LarkUIKit
import RoundedHUD
import LarkContainer

typealias IconButton = LarkButton.IconButton

struct SideBarCalendars {
    var mineCalendars: [SidebarCellContent]
    var bookedCalendars: [SidebarCellContent]
    var googleCalendars: [[SidebarCellContent]]
    var exchangeCalendars: [[SidebarCellContent]]
    init(mycals: [SidebarCellContent], bookedCals: [SidebarCellContent], googleCals: [[SidebarCellContent]], exchangeCals: [[SidebarCellContent]]) {
        mineCalendars = mycals
        bookedCalendars = bookedCals
        googleCalendars = googleCals
        exchangeCalendars = exchangeCals
    }
}

struct SidebarCellModel: SidebarCellContent {
    var calendarDependency: CalendarDependency?
    var userInfo: [String: Any] = [:]
    var type: SideBarCellType
    var canModify: Bool {
        return !self.hasGoogleLogo && !self.hasExchangeLogo && !self.isLocal
    }
    var isActive: Bool
    var isLocal: Bool
    var description: String?
    var sourceTitle: String
    var id: String
    var hasGoogleLogo: Bool
    var hasExchangeLogo: Bool
    var isChecked: Bool
    var color: UIColor
    var text: String
    var isPrimary: Bool
    var isDisabled: Bool
    var isExternal: Bool
    var needApproval: Bool
    var isLoading: Bool
    var externalAccountValid: Bool
    var isDismissed: Bool

    init(calendarDependency: CalendarDependency?,
         calendarModel: CalendarModel,
         isLoading: Bool,
         type: SideBarCellType,
         userTenantId: String) {
        self.calendarDependency = calendarDependency
        self.id = calendarModel.serverId
        self.isPrimary = calendarModel.isPrimary
        self.hasGoogleLogo = calendarModel.isGoogleCalendar()
        self.hasExchangeLogo = calendarModel.isExchangeCalendar()
        self.isChecked = calendarModel.isVisible
        self.color = SkinColorHelper.pickerColor(of: calendarModel.colorIndex.rawValue)
        self.text = calendarModel.displayName()
        self.description = calendarModel.description
        self.isActive = calendarModel.isActive
        self.isLoading = isLoading
        self.isLocal = false
        self.isDisabled = calendarModel.isDisabled
        self.needApproval = calendarModel.needApproval
        self.type = type
        self.externalAccountValid = calendarModel.externalAccountValid
        let successorChatterID = calendarModel.getCalendarPB().successorChatterID
        let isResigned = !(successorChatterID.isEmpty || successorChatterID == "0")
        self.isDismissed = isResigned

        self.isExternal = calendarModel.getCalendarPB().cd.isExternalCalendar(userTenantId: userTenantId)

        if type == .larkMine {
            self.sourceTitle = BundleI18n.Calendar.Calendar_Common_MyCalendars
        } else if type == .larkSubscribe {
            self.sourceTitle = BundleI18n.Calendar.Calendar_Common_SubscribedCalendar
        } else if type == .google {
            self.sourceTitle = calendarModel.externalAccountName
        } else if type == .exchange {
            self.sourceTitle = calendarModel.externalAccountName
        } else {
            assertionFailureLog()
            self.sourceTitle = ""
        }
        if calendarModel.type == .resources {
            self.userInfo[CalendarTracer.CalToggleCalendarVisibilityParam.CalendarTypeKey]
                = CalendarTracer.CalToggleCalendarVisibilityParam.CalendarType.meetingRoom
        } else if calendarModel.type == .other {
            self.userInfo[CalendarTracer.CalToggleCalendarVisibilityParam.CalendarTypeKey]
                = CalendarTracer.CalToggleCalendarVisibilityParam.CalendarType.publicCalendar
        } else {
            self.userInfo[CalendarTracer.CalToggleCalendarVisibilityParam.CalendarTypeKey]
                = CalendarTracer.CalToggleCalendarVisibilityParam.CalendarType.contacts
        }
    }

    init(model: LocalCalSidebarModel) {
        self.id = model.calIdentifier
        self.isPrimary = false
        self.isActive = true
        self.hasGoogleLogo = false
        self.hasExchangeLogo = false
        self.isChecked = model.selected
        self.color = model.color
        self.text = model.title
        self.isLocal = true
        self.isDisabled = false
        self.sourceTitle = model.sourceTitle
        self.type = .local
        self.isLoading = false
        self.needApproval = false
        self.externalAccountValid = false
        self.isDismissed = false
        self.isExternal = false
    }
}
