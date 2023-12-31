//
//  EventDetailTableVideoMeetingViewModel+PBExt.swift
//  ByteViewMod
//
//  Created by tuwenbo on 2022/9/26.
//

import Foundation


extension Rust.CalendarEvent {
    var displayTitle: String {
        if displayType == .full {
            return summary.isEmpty ? I18n.Calendar_Common_NoTitle : summary
        } else if category == .resourceStrategy {
            return I18n.Calendar_MeetingView_MeetingRoomCantReservePeriod
        } else if category == .resourceRequisition {
            return I18n.Calendar_Edit_MeetingRoomInactiveCantReserve
        } else {
            return selfAttendeeStatus.freeBusyStatusString
        }
    }
}

extension Rust.CalendarEventAttendee {
    var tenantID: String {
        switch category {
        case .user:
            return user.tenantID
        case .group:
            return group.tenantID
        case .resource:
            return resource.tenantID
        case .thirdPartyUser:
            return ""
        @unknown default:
            return ""
        }
    }
}

extension Rust.CalendarEventAttendee.Status {
    var freeBusyStatusString: String {
        switch self {
        case .accept: return I18n.Calendar_Detail_Busy
        case .needsAction: return I18n.Calendar_MV_ColorBlockNeedAction
        case .tentative: return I18n.Calendar_MV_ColorBlockNotSure
        @unknown default: return I18n.Calendar_Detail_Busy
        }
    }
}
