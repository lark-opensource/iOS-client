//
//  AlertMessage+MeetingRoom.swift
//  Calendar
//
//  Created by Miao Cai on 2020/9/2.
//

import RustPB
import Foundation
import CalendarFoundation
import LarkTimeFormatUtils

extension ScrollableAlertMessage {
    static func create(
        from unusableReasonMap: Rust.UnusableReasonMap,
        with meetingRooms: [CalendarMeetingRoom],
        startDate: Date,
        endDate: Date,
        is12HourStyle: Bool,
        timeZone: TimeZone
    ) -> [ScrollableAlertMessage] {
        return meetingRooms.compactMap { meetingRoom -> ScrollableAlertMessage? in
            guard let unusableReasons = unusableReasonMap[meetingRoom.uniqueId] else { return nil }
            let content = contents(
                from: unusableReasons,
                by: meetingRoom,
                startDate: startDate,
                endDate: endDate,
                is12HourStyle: is12HourStyle,
                timeZone: timeZone
            )
            guard !content.isEmpty else { return nil }
            return ScrollableAlertMessage(
                title: meetingRoom.fullName,
                content: content
            )
        }
    }

    static func contents(
        from unusableReasons: Rust.UnusableReasons,
        by meetingRoom: CalendarMeetingRoom,
        startDate: Date,
        endDate: Date,
        is12HourStyle: Bool,
        timeZone: TimeZone
    ) -> [String] {
        let meetingRoomTimeZoneID = meetingRoom.resourceStrategy?.timezone ?? TimeZone.current.identifier
        return unusableReasons.unusableReasons.compactMap { reason -> String? in
            switch reason {
            case .notInUsableTime:
                guard let startTime = meetingRoom.resourceStrategy?.dailyStartTime,
                      let endTime = meetingRoom.resourceStrategy?.dailyEndTime else {
                          assertionFailure("Single reservation time is invaild")
                          return nil
                      }
                return CalendarMeetingRoom.usableTimeText(
                    eventStartDate: startDate,
                    dailyStartTime: TimeInterval(startTime), dailyEndTime: TimeInterval(endTime),
                    eventTimeZoneId: timeZone.identifier, meetingRoomTimeZoneId: meetingRoomTimeZoneID
                )
            case .beforeEarliestBookTime:
                guard let regularReservableTime = meetingRoom.resourceStrategy?.earliestBookTime else {
                    return nil
                }
                return CalendarMeetingRoom.earliestBookTimeText(
                    regularReservableTime: TimeInterval(regularReservableTime),
                    meetingRoomTimeZone: meetingRoomTimeZoneID
                )
            case .overMaxDuration:
                guard let maxSingleDuration = meetingRoom.resourceStrategy?.singleMaxDuration else { return nil }

                return CalendarMeetingRoom.maxDurationText(fromSeconds: maxSingleDuration)
            case .overMaxUntilTime:
                return CalendarMeetingRoom.furthestBookTimeText(
                    furthestTime: meetingRoom.resourceStrategy?.furthestBookTime ?? Rust.ResourceStrategy.maxReservableDate
                )
            case .duringRequisition:
                guard let startINT = meetingRoom.resourceRequisition?.startTime,
                      let endINT = meetingRoom.resourceRequisition?.endTime else { return nil }
                if Int64(Date().timeIntervalSince1970) > endINT && endINT != 0 { return nil }
                return CalendarMeetingRoom.requisitionText(
                    requiStartTime: TimeInterval(startINT), requiEndTime: TimeInterval(endINT),
                    eventTimeZoneId: timeZone.identifier, meetingRoomTimeZoneId: meetingRoomTimeZoneID
                )
            case .pastTime:
                return BundleI18n.Calendar.Calendar_Edit_MeetingRoomCantReserveForPastEvent
            case .recurrentEventDurationTriggersApproval:
                guard let trigger = meetingRoom.getPBModel().schemaExtraData.cd.conditionalApprovalTriggerDuration else { return nil }
                let duration = Double(trigger) / 3600.0
                return BundleI18n.Calendar.Calendar_Rooms_CantReserveOverTime(num: String(format: "%g", duration))
            case .unknown:
                return BundleI18n.Calendar.Calendar_MeetingView_NoReserveNow
            @unknown default:
                return nil
            }
        }
    }

    static func contents(
        from unusableReasons: Server.UnusableReasons,
        by meetingRoom: CalendarMeetingRoom,
        startDate: Date,
        endDate: Date,
        is12HourStyle: Bool,
        timeZone: TimeZone
    ) -> [String] {
        let meetingRoomTimeZoneID = meetingRoom.resourceStrategy?.timezone ?? TimeZone.current.identifier
        return unusableReasons.compactMap { reason -> String? in
            switch reason {
            case .overMaxDuration:
                guard let maxSingleDuration = meetingRoom.resourceStrategy?.singleMaxDuration else { return nil }

                return CalendarMeetingRoom.maxDurationText(fromSeconds: maxSingleDuration)
            case .overMaxUntilTime:
                return CalendarMeetingRoom.furthestBookTimeText(
                    furthestTime: meetingRoom.resourceStrategy?.furthestBookTime ?? Rust.ResourceStrategy.maxReservableDate
                )
            case .notInUsableTime:
                guard let startTime = meetingRoom.resourceStrategy?.dailyStartTime,
                      let endTime = meetingRoom.resourceStrategy?.dailyEndTime else {
                          assertionFailure("Single reservation time is invaild")
                          return nil
                      }
                return CalendarMeetingRoom.usableTimeText(
                    eventStartDate: startDate,
                    dailyStartTime: TimeInterval(startTime), dailyEndTime: TimeInterval(endTime),
                    eventTimeZoneId: timeZone.identifier, meetingRoomTimeZoneId: meetingRoomTimeZoneID
                )
            case .duringRequisition:
                guard let startINT = meetingRoom.resourceRequisition?.startTime,
                      let endINT = meetingRoom.resourceRequisition?.endTime else { return nil }
                if Int64(Date().timeIntervalSince1970) > endINT && endINT != 0 { return nil }
                return CalendarMeetingRoom.requisitionText(
                    requiStartTime: TimeInterval(startINT), requiEndTime: TimeInterval(endINT),
                    eventTimeZoneId: timeZone.identifier, meetingRoomTimeZoneId: meetingRoomTimeZoneID
                )
            case .pastTime:
                return BundleI18n.Calendar.Calendar_Edit_MeetingRoomCantReserveForPastEvent
            case .beforeEarliestBookTime:
                guard let regularReservableTime = meetingRoom.resourceStrategy?.earliestBookTime else {
                    return nil
                }
                return CalendarMeetingRoom.earliestBookTimeText(
                    regularReservableTime: TimeInterval(regularReservableTime),
                    meetingRoomTimeZone: meetingRoomTimeZoneID
                )
            case .reservedByOtherEvent:
                return BundleI18n.Calendar.Calendar_MeetingRoom_SomeoneAlreadyReserved
            case .cantReserveOverTime:
                guard let trigger = meetingRoom.getPBModel().schemaExtraData.cd.conditionalApprovalTriggerDuration else { return nil }
                let duration = Double(trigger) / 3600.0
                return BundleI18n.Calendar.Calendar_Rooms_CantReserveOverTime(num: String(format: "%g", duration))
            case .unknownUnusableReason:
                return BundleI18n.Calendar.Calendar_MeetingView_NoReserveNow
            case .overUsageLimit:
                return BundleI18n.Calendar.Calendar_RoomNumberReachMax
            case .forbidInRecursive:
                return BundleI18n.Calendar.Calendar_MeetingView_RecurringNoReserve
            case .overOnePerEvent:
                return BundleI18n.Calendar.Calendar_MeetingView_OnlyOneCanReserve
            @unknown default:
                return nil
            }
        }
    }
}
