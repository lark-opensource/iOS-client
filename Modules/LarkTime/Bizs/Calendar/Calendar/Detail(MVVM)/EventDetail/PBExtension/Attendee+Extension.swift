//
//  Attendee+Extension.swift
//  Calendar
//
//  Created by Rico on 2021/4/6.
//

import Foundation
import RustPB

extension DetailLogicBox where Base == EventDetail.Attendee {

    var tenantId: String {
        switch source.category {
        case .user:
            return source.user.tenantID
        case .group:
            return source.group.tenantID
        case .resource:
            return source.resource.tenantID
        case .thirdPartyUser:
            return ""
        @unknown default:
            return ""
        }
    }
}

extension DetailLogicBox: Avatar where Base == EventDetail.Attendee {
    var avatarKey: String {
        return source.avatarKey
    }

    var identifier: String {
        switch source.category {
        case .user:
            return source.user.userID
        case .group:
            return source.group.groupID
        @unknown default:
            return ""
        }
    }

    var userName: String {
        return source.displayName
    }
}

// 会议室相关
extension DetailLogicBox where Base == EventDetail.Attendee {
    func statusSummary(isInRequi: Bool) -> String? {
        if isInRequi { return BundleI18n.Calendar.Calendar_Meeting_FailedToReserve + " " }
        if source.status == .tentative || source.status == .needsAction {
            if !source.attendeeSchema.approvalLink.isEmpty {
                return BundleI18n.Calendar.Calendar_Approval_InReview + " "
            }
            return BundleI18n.Calendar.Calendar_Detail_ReservingMobile + " "
        }
        if source.status == .decline || source.status == .removed {
            if source.resource.resourceStatus == .releasedEarly {
                return BundleI18n.Calendar.Calendar_Bot_MeetingRoomReleased + " "
            }
            return BundleI18n.Calendar.Calendar_Meeting_FailedToReserve + " "
        }
        return nil
    }
}

// 可见参与者展示
extension DetailLogicBox where Base == EventDetail.Attendee {
    func areInIncreasingOrder(with rhs: DetailLogicBox<EventDetail.Attendee>, eventDisplayCalId: String) -> Bool {
        /// 群放最后面
        if (source.category == .group) != (rhs.source.category == .group) {
            return !(source.category == .group)
        }
        /// 组织者最前面
        let isDisplayOrganinzer = source.attendeeCalendarID == eventDisplayCalId
        let rhsIsDisplayOrganinzer = rhs.source.attendeeCalendarID == eventDisplayCalId
        if isDisplayOrganinzer != rhsIsDisplayOrganinzer {
            return isDisplayOrganinzer
        }
        /// 接受 > 拒绝 > 待定 > 待操作
        if source.status != rhs.source.status {
            return source.status.dt > rhs.source.status.dt
        }
        return source.displayName.localizedCompare(rhs.source.displayName) == .orderedAscending
    }
}

// MARK: - Attendee Status Comparable
extension DetailLogicBox: Equatable where Base == EventDetail.Attendee.Status {
    static func == (lhs: DetailLogicBox, rhs: DetailLogicBox) -> Bool {
        lhs.source == rhs.source
    }

    var description: String {
        switch source {
        case .accept: return "accept"
        case .needsAction: return "needsAction"
        case .decline: return "decline"
        case .removed: return "removed"
        case .tentative: return "tentative"
        @unknown default: return ""
        }
    }
}

extension DetailLogicBox: Comparable where Base == EventDetail.Attendee.Status {
    /// removed  < needsAction < tentative < decline < accept
    private static func minimum(_ lhs: DetailLogicBox, _ rhs: DetailLogicBox) -> EventDetail.Attendee.Status {
        switch (lhs.source, rhs.source) {
        case (.removed, _), (_, .removed): return .removed
        case (.needsAction, _), (_, .needsAction): return .needsAction
        case (.tentative, _), (_, .tentative): return .tentative
        case (.decline, _), (_, .decline): return .decline
        case (.accept, _), (_, .accept): return .accept
        @unknown default: return .removed
        }
    }

    static func < (lhs: DetailLogicBox, rhs: DetailLogicBox) -> Bool {
        return (lhs != rhs) && (lhs == DetailLogicBox.minimum(lhs, rhs).dt)
    }
}

extension DetailLogicBox where Base == EventDetail.Attendee {

    var debugDescription: String {
        return source.debugDescription
    }

    var description: String {
        return """
        id: \(source.id),
        key: \(source.key),
        originalTime: \(source.originalTime),
        attendeeCalendarID: \(source.attendeeCalendarID),
        status: \(source.status),
        attendeeSchema: \(source.attendeeSchema),
        schemaExtra: \(source.schemaExtraData),
        user: \(source.user.userID),
        group: \(source.group.groupID),
        resource: \(source.resource.bookerID)
        """
    }
}
