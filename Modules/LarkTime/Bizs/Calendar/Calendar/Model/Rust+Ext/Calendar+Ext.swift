//
//  Calendar+Ext.swift
//  Calendar
//
//  Created by Rico on 2021/8/19.
//

import Foundation
import RustPB

extension Rust.Calendar {

    /// 日历是否显示「外部」标签（不仅和日历本身是外部租户有关系，也和订阅成员有关系）
    /// - Parameter userTenantID: 租户ID
    /// - Returns: result
    func showExternalTag(with userTenantId: String) -> Bool {

        let isExternalCalendar = calendarTenantID != userTenantId && !calendarTenantID.isEmpty && calendarTenantID != "0"
        switch type {
        case .other, .activity:
            return isExternalCalendar || isCrossTenant
        case .primary:
            return isExternalCalendar
        @unknown default:
            return false
        }
    }

    /// 日历的「所有者」 最高权限
    func isAbsoluteOwnerWith(currentUserID: String) -> Bool {
        return currentUserID == calendarOwnerID
    }

    /// 日历是否有「所有者」
    var hasAbsoluteOwner: Bool {
        guard hasCalendarOwnerID,
              !calendarOwnerID.isEmpty,
              calendarOwnerID != "0" else {
            return false
        }
        return true
    }

    var avatarKey: String {
        get { coverImageSet.origin.key }
        set { coverImageSet.origin.key = newValue }
    }

    func unShareableInfo(tenantID: String?, isCrossTenant: Bool?) -> String? {
        if selfAccessRole != .owner {
            let isCrossCalendarTenant: Bool
            if let tenantId = tenantID {
                isCrossCalendarTenant = calendarTenantID != tenantId
            } else {
                // 无 tenantID，用搜索传过来的 isCrossTenant 判断， 默认按跨租户处理
                isCrossCalendarTenant = isCrossTenant ?? true
            }
            if shareOptions.crossDefaultShareOption == .shareOptPrivate && shareOptions.defaultShareOption == .shareOptPrivate {
                // 无权限分享日历
                return I18n.Calendar_Share_UnableShareDialogue
            } else if shareOptions.crossDefaultShareOption == .shareOptPrivate && isCrossCalendarTenant {
                // 无权限将日历分享给日历外部用户
                return I18n.Calendar_Share_UnableShareExternalUsersDialogue(user: owner.localizedName)
            } else if shareOptions.defaultShareOption == .shareOptPrivate && !isCrossCalendarTenant {
                // 无权限将日历分享给日历内部用户
                return I18n.Calendar_Share_UnableShareExternalUsersDialogue(user: owner.localizedName)
            }
        }
        return nil
    }
}
