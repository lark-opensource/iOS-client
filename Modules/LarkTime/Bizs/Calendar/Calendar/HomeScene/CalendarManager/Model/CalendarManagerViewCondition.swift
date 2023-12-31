//
//  CalendarManagerViewModel.swift
//  Calendar
//
//  Created by harry zou on 2019/3/21.
//

import Foundation
import CalendarFoundation

enum CalendarEditInput {
    /// 新建日历
    case fromCreate
    /// 编辑日历
    case fromEdit(calendar: Rust.Calendar)
}

extension CalendarEditInput {
    var isFromCreate: Bool {
        switch self {
        case .fromCreate: return true
        case .fromEdit: return false
        }
    }
}

struct CalendarEditPermission {
    var authInfo: CalendarModel.EditAuthInfo
    var isFromCreat: Bool
    var isAllStaff = false

    init(calendarfrom: CalendarEditInput) {
        switch calendarfrom {
        case .fromCreate:
            isFromCreat = true
            self.authInfo = CalendarModel.EditAuthInfo()
            authInfo.isSummaryEditable = true
            authInfo.isNoteEditable = false
            authInfo.isVisibilityEditable = true
            authInfo.isColorEditable = true
            authInfo.isDiscriptionEditable = true
            authInfo.isMemberEditable = true
            authInfo.isUnsubscribable = false
            authInfo.isDeletable = false
            authInfo.isCoverImageEditable = true
        case .fromEdit(let calendar):
            isFromCreat = false
            self.isAllStaff = calendar.isAllStaff
            self.authInfo = calendar.authInfo.editAuthInfo
        }
    }

    var isCalSummaryEditable: Bool { authInfo.isSummaryEditable }
    var isCalSummaryRemarkVisible: Bool { authInfo.isNoteEditable }
    var isPermissionEditable: Bool { authInfo.isVisibilityEditable }
    var isColorEditable: Bool { authInfo.isColorEditable }
    var isDescEditable: Bool { authInfo.isDiscriptionEditable }
    var isCalMemberEditable: Bool { authInfo.isMemberEditable }
    var isUnsubscriable: Bool { authInfo.isUnsubscribable }
    var isDeleteable: Bool { authInfo.isDeletable }
    var isCoverImageEditable: Bool { authInfo.isCoverImageEditable }
}
