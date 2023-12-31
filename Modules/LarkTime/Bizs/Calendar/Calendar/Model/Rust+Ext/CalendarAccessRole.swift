//
//  CalendarAccessRole.swift
//  Calendar
//
//  Created by zhuheng on 2021/7/13.
//

import Foundation
import RustPB
import CalendarFoundation

extension CalendarExtension where BaseType == Rust.CalendarAccessRole {
    var shareOption: String {
        switch base {
        case .unknownAccessRole:
            return I18n.Calendar_Share_Guest_Option
        case .freeBusyReader:
            return I18n.Calendar_Share_Guest_Option
        case .reader:
            return I18n.Calendar_Share_Follower_Option
        case .writer:
            return I18n.Calendar_Share_Editor_Option
        case .owner:
            return I18n.Calendar_Share_Administrator_Option
        @unknown default:
            return I18n.Calendar_Share_Guest_Option
        }
    }

    var shareOptionDescription: String {
        switch base {
        case .unknownAccessRole:
            return I18n.Calendar_Share_OnlyBusyFree
        case .freeBusyReader:
            return I18n.Calendar_Share_OnlyBusyFree
        case .reader:
            return I18n.Calendar_Share_SeeAllEventDetails
        case .writer:
            return I18n.Calendar_Share_CreateAndEditEvents
        case .owner:
            return I18n.Calendar_Share_ManageCalendar
        @unknown default:
            return I18n.Calendar_Share_OnlyBusyFree
        }
    }
}

extension Rust.CalendarAccessRole: CalendarExtensionCompatible {}

extension Rust.CalendarAccessRole: Comparable {
    public static func < (lhs: Calendar_V1_Calendar.AccessRole, rhs: Calendar_V1_Calendar.AccessRole) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
