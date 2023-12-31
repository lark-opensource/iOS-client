//
//  RruleInvalidWarningType.swift
//  Calendar
//
//  Created by Miao Cai on 2020/9/16.
//

import Foundation

enum RruleInvalidWarningType {
    // 日程的开始时间晚于截止日期
    case startDateLaterThanDueDate
    // 会议室可预约的最长日期早于截止日期
    case meetingRoomReservableDateEarlierThanDueDate(MeetingRoomAmountType, String)
    // 会议室可预约的最长日期早于日程的开始时间
    case meetingRoomReservableDateEarlierThanStartDate(MeetingRoomAmountType, String)

    enum MeetingRoomAmountType {
        // 会议室个数为 1 时不显示会议室名称
        case one
        // 会议室个数 > 1 时需要显示会议室名称
        case some(String)
    }
}

extension RruleInvalidWarningType {

    var readableStr: String {
        switch self {
        case .startDateLaterThanDueDate:
            return BundleI18n.Calendar.Calendar_Edit_EndDateAlert
        case .meetingRoomReservableDateEarlierThanDueDate(let type, let dateStr):
            switch type {
            case .one:
                return BundleI18n.Calendar.Calendar_Edit_SpecificMeetingRoomAndReserveDueDate(DueDate: dateStr)
            case .some(let name):
                return BundleI18n.Calendar.Calendar_Edit_SpecificMeetingRoomAndReserveDueDateMulti(MeetingRoom: name, DueDate: dateStr)
            }
        case .meetingRoomReservableDateEarlierThanStartDate(let type, let dateStr):
            switch type {
            case .one:
                return BundleI18n.Calendar.Calendar_Edit_MeetingRoomCantReserveBeyond(DueDate: dateStr)
            case .some(let name):
                return BundleI18n.Calendar.Calendar_Edit_MeetingRoomCantReserveBeyondMulti(MeetingRoom: name, DueDate: dateStr)
            }
        }
    }
}
