//
//  RSVP.swift
//  Calendar
//
//  Created by Rico on 2022/4/18.
//

import Foundation
import RustPB

extension Calendar_V1_CalendarEventAttendee.Status {

    // 用于查看他人日程时的展示文案

    var freeBusyStatusString: String {
        switch self {
        case .accept: return I18n.Calendar_Detail_Busy
        case .needsAction: return I18n.Calendar_MV_ColorBlockNeedAction
        case .tentative: return I18n.Calendar_MV_ColorBlockNotSure
        @unknown default: return I18n.Calendar_Detail_Busy
        }
    }
}
