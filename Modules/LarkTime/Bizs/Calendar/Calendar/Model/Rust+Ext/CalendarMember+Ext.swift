//
//  CalendarMember+Ext.swift
//  Calendar
//
//  Created by zhuheng on 2021/7/11.
//

import Foundation
import RustPB
import CalendarFoundation

/// Rust CalendarWithMember 结构只有 CalendarID，封装方便使用。
struct CalendarWithMember: Equatable {
    var tenantInfo: Rust.CalendarTenantInfo
    var calendar: Rust.Calendar
    var members: [Rust.CalendarMember]
}

extension CalendarExtension where BaseType == Rust.Calendar {
    func isExternalCalendar(userTenantId: String) -> Bool {
        var isExternal: Bool = false

        let isExternalCalendar = base.calendarTenantID != userTenantId && !base.calendarTenantID.isEmpty && base.calendarTenantID != "0"
        switch base.type {
        case .other, .activity:
            isExternal = isExternalCalendar || base.isCrossTenant
        case .primary:
            isExternal = isExternalCalendar
        @unknown default:
            isExternal = false
        }

        return isExternal
    }
}

extension Rust.Calendar: CalendarExtensionCompatible {}

extension Rust.CalendarMember {
    var memberID: String {
        memberType == .group ? chatID : userID
    }

    var displayName: String {
        if memberType == .group && isUserCountVisible {
            return name + "(\(chatMemberCount))"
        } else {
            return name
        }
    }
}

extension CalendarExtension where BaseType == [Rust.CalendarMember] {
    func member(atUserID userID: String) -> Rust.CalendarMember? {
        base.first { $0.userID == userID }
    }
}

extension Array: CalendarExtensionCompatible {}

extension CalendarWithMember {

    /// 主日历的头像key
    var primaryAvatar: (key: String, idendifier: String)? {
        guard calendar.type == .primary else {
            return nil
        }
        guard let user = members.cd.member(atUserID: calendar.userID) else {
            return nil
        }
        let identifier: String
        if user.memberType == .group {
            identifier = user.chatID
        } else {
            identifier = user.userID
        }
        return (user.avatarKey, identifier)
    }

    /// 日历的所有者
    var absoluteOwner: Rust.CalendarMember? {
        guard calendar.hasAbsoluteOwner else {
            return nil
        }
        return members.cd.member(atUserID: calendar.calendarOwnerID)
    }

    /// 日历的第一个找到的管理员
    var firstOwner: Rust.CalendarMember? {
        return members.first { $0.accessRole == .owner }
    }
}
