//
//  DayScene+ViewDataUtil.swift
//  Calendar
//
//  Created by 张威 on 2020/8/20.
//

import UIKit
import Foundation
import LarkExtensions

/// 抽象一些日视图 viewData 相关 API

extension DayScene {

    // MARK: Title & Subtitle

    static func title(from instance: Instance, in calendar: CalendarModel?) -> String {
        switch instance.displayType {
        case .full:
            var summary: String
            switch instance {
            case .local(let localInstance): summary = localInstance.title ?? ""
            case .rust(let rustInstance): summary = rustInstance.summary
            }
            summary = summary.isEmpty ? BundleI18n.Calendar.Calendar_Common_NoTitle : summary
            return summary
        case .limited:
            let limitedTitle: String
            switch instance {
            case .local(let localInstance):
                let title = localInstance.title ?? ""
                limitedTitle = title.isEmpty ? BundleI18n.Calendar.Calendar_Common_NoTitle : title
            case .rust(let rustInstance):

                limitedTitle =
                rustInstance.isFree ? BundleI18n.Calendar.Calendar_Detail_Free : (rustInstance.selfAttendeeStatus.freeBusyStatusString)
            }
            guard let calendar = calendar else { return limitedTitle }
            if calendar.type == .googleResource || calendar.type == .resources {
                if instance.isCreatedByMeetingRoom.strategy {
                    return BundleI18n.Calendar.Calendar_MeetingView_MeetingRoomCantReservePeriodMobile(meetingRoom: calendar.displayName())
                } else if instance.isCreatedByMeetingRoom.requisition {
                    return BundleI18n.Calendar.Calendar_Edit_MeetingRoomInactiveCantReserveVariable(RoomName: calendar.displayName())
                } else {
                    return BundleI18n.Calendar.Calendar_Meeting_Reserved(meetingRoom: calendar.displayName())
                }
            } else if calendar.type == .other {
                return "\(calendar.displayName()), \(limitedTitle)"
            } else {
                return "\(calendar.parentDisplayName()), \(limitedTitle)"
            }
        case .invisible:
            DayScene.assertionFailure()
            return ""
        case .undecryptable:
            return I18n.Calendar_EventExpired_GreyText
        @unknown default:
            return ""
        }
    }

    static func subtitle(from instance: Instance) -> String? {
        switch instance {
        case .local(let localInstance):
            guard case .full = localInstance.displayType else { return nil }
            if let title = localInstance.structuredLocation?.title, !title.isEmpty {
                return title
            } else {
                return nil
            }
        case .rust(let rustInstance):
            guard case .full = rustInstance.displayType else { return nil }
            var strs = rustInstance.meetingRooms
            if !rustInstance.location.location.isEmpty {
                strs.append(rustInstance.location.location)
            }
            return strs.isEmpty ? nil : strs.joined(separator: ", ")
        }
    }

    // MARK: Type Icon Image

    static func typeIconImage(for instance: Instance) -> UIImage? {
        var image: UIImage?
        switch instance {
        case .local:
            image = DayScene.localIcon
        case .rust(let rustInstance):
            switch rustInstance.source {
            case .exchange:
                image = DayScene.exchangeIcon
            case .google:
                image = DayScene.googleIcon
            @unknown default:
                break
            }
        }
        return image
    }

}
