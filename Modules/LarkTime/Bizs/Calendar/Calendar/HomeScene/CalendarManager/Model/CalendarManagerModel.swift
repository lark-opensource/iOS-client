//
//  CalendarManagerModel.swift
//  Calendar
//
//  Created by harry zou on 2019/3/28.
//

import UIKit
import Foundation
import CalendarFoundation

class CalendarManagerModel: CalendarManagerViewProtocol, CalendarManagerDataProtocol {
    var canAddNewMember: Bool {
        return calendarMembersInitiated
    }

    enum Err: Error {
        case invaildResponseCount
    }

    var skinType: CalendarSkinType
    private let selfUserId: String

    var calendar: CalendarModel
    var calendarMembers: [CalendarMember] = []
    var calendarMembersInitiated = false // 编辑日历时，member初始化之前不能进行保存或者添加member操作

    var calSummary: String {
        get {
            return calendar.localizedSummary.isEmpty ? calendar.summary : calendar.localizedSummary
        }
        set {
            calendar.summary = newValue
        }
    }
    var calSummaryRemark: String? {
        get {
            return calendar.note
        }
        set {
            calendar.note = newValue ?? ""
        }
    }
    var permission: CalendarAccess {
        get {
            return calendar.calendarAccess
        }
        set {
            calendar.calendarAccess = newValue
        }
    }
    var color: UIColor { SkinColorHelper.pickerColor(of: colorIndex.rawValue) }

    var colorIndex: ColorIndex {
        get {
            return calendar.colorIndex
        }
        set {
            calendar.colorIndex = newValue
        }
    }

    var desc: String {
        get {
            return calendar.description ?? ""
        }
        set {
            calendar.description = newValue
        }
    }

    var calMemberCellModels: [CalendarMemberCellModel] {
        return calendarMembers.toCalendarMemberCellModel(haveOwnerAccess: calendar.selfAccessRole == .owner,
                                                         ownerUserId: calendar.getCalendarPB().userID,
                                                         selfUserId: selfUserId)
    }

    var rejectedUserIDs: [String] = []

    required init(calendar: CalendarModel,
         members: [CalendarMember],
         skinType: CalendarSkinType,
         selfUserId: String) {
        self.calendar = calendar
        self.skinType = skinType
        self.calendarMembers = members
        self.selfUserId = selfUserId
    }
}
