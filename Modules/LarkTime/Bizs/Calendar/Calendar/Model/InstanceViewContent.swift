//
//  InstanceViewContent.swift
//  Calendar
//
//  Created by zhouyuan on 2018/10/22.
//  Copyright © 2018 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation

typealias AllDayEventRange = (start: Int, long: Int)

protocol InstanceBaseInfo {
    var backgroundColor: UIColor { get }
    var foregroundColor: UIColor { get }

    var titleText: String { get }

    var indicatorInfo: (color: UIColor, isStripe: Bool)? { get set }
    var hasStrikethrough: Bool { get }
    var stripBackgroundColor: UIColor? { get }
    var stripLineColor: UIColor? { get }
    var dashedBorderColor: UIColor? { get set }

    // 虚假日程的特殊样式
    var strokeDashLineColor: UIColor? { get }
    var startDate: Date { get set }
    var endDate: Date { get set }
    // 儒略日
    var startDay: Int32 { get set }
    var endDay: Int32 { get set }
    var userInfo: [String: Any] { get }
    var isCoverPassEvent: Bool { get }
    var maskOpacity: Float { get }
}

extension InstanceBaseInfo {
    var strokeDashLineColor: UIColor? { nil }
}

final class InstanceBaseFunc {
    static func getTitleFromModel(model: TimeBlockModel) -> String {
        return model.title
    }

    static func getTitleFromModel(model: CalendarEventInstanceEntity,
                           calendar: CalendarModel?) -> String {

        switch model.displayType {
        case .full:
            return model.displaySummary()
        case .limited:
            if let calendar = calendar {
                if calendar.type == .googleResource || calendar.type == .resources {
                    let appendStr: String
                    if model.isCreatedByMeetingRoom.strategy {
                        appendStr = BundleI18n.Calendar.Calendar_MeetingView_MeetingRoomCantReservePeriodMobile(meetingRoom: calendar.displayName())
                    } else if model.isCreatedByMeetingRoom.requisition {
                        appendStr = BundleI18n.Calendar.Calendar_Edit_MeetingRoomInactiveCantReserveVariable(RoomName: calendar.displayName())
                    } else {
                        appendStr = BundleI18n.Calendar.Calendar_Meeting_Reserved(meetingRoom: calendar.displayName())
                    }
                    return appendStr
                }

                if calendar.type == .other {
                    return calendar.displayName() + ", " + model.displaySummary()
                }

                return calendar.parentDisplayName() + ", " + model.displaySummary()
            } else {
                return model.displaySummary()
            }
        case .invisible:
            assertionFailureLog()
            return ""
        case .undecryptable:
            return I18n.Calendar_EventExpired_GreyText
        @unknown default:
            return ""
        }
    }

    static func getSubTitleFromModel(model: CalendarEventInstanceEntity) -> String {
        func getLocationStr(eventLocation: String?) -> String {
            if let eventLocation = eventLocation, !eventLocation.isEmpty {
                return ", \(eventLocation)"
            } else {
                return ""
            }
        }
        if model.displayType != .full {
            return ""
        }
        let rooms = model.meetingRomes.enumerated().reduce("") { (result, element) -> String in
            let (offset, v) = element
            return offset == 0 ? v : "\(result), \(v)"
        }
        return (rooms.isEmpty ? model.location : "\(rooms) \(getLocationStr(eventLocation: model.location))")
    }
}
