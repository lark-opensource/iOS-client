//
//  ArrangementHeaderViewModel.swift
//  Calendar
//
//  Created by harry zou on 2019/3/19.
//

import Foundation
import LarkTimeFormatUtils
import RustPB

protocol ArrangementHeaderViewModelProtocol {
    var cellModels: [ArrangementHeaderViewCellModel] { get set }
    var shouldShowTimeString: Bool { get }
    var is12HourStyle: Bool { get }
}

struct StartTimeInfo: Equatable {
    let timeString: String
    let timezoneString: String
}

struct ArrangementHeaderViewModel: ArrangementHeaderViewModelProtocol {
    let shouldShowTimeString: Bool
    var cellModels: [ArrangementHeaderViewCellModel]
    let is12HourStyle: Bool

    init(attendees: [UserAttendeeBaseDisplayInfo],
         startTime: Date,
         timezoneMap: [String: String],
         privateCalMap: [String: Bool],
         conflictCalendarIds: [String],
         notWorkingCalendarIds: [String],
         currentUserCalendarId: String? = nil,
         is12HourStyle: Bool,
         sunStateService: SunStateService) {
        self.is12HourStyle = is12HourStyle
        let startTimeMap = FreeBusyUtils.getStartTimeMap(timezoneMap: timezoneMap,
                                                       attendees: attendees,
                                                       startTime: startTime,
                                                       is12HourStyle: is12HourStyle)
        let hasDifferentTimezone = FreeBusyUtils.hasDifferentTimezone(startTimeMap: startTimeMap)
        self.shouldShowTimeString = hasDifferentTimezone

        var tenantIDMap: [String: String] = [:]
        attendees.forEach { info in
            tenantIDMap[info.tenantId] = info.tenantId
        }
        let isCrossTenant = tenantIDMap.count > 1
        
        self.cellModels = attendees.map { (attendee) -> ArrangementHeaderViewCellModel in
            var name = attendee.name
            let calendarId = attendee.calendarId
            var timeInfo = hasDifferentTimezone ? startTimeMap[calendarId] : nil
            
            if let currentUserCalendarId = currentUserCalendarId {
                timeInfo = (hasDifferentTimezone && !isCrossTenant) ? startTimeMap[calendarId] : nil
                if currentUserCalendarId == attendee.calendarId {
                    name = BundleI18n.Calendar.Calendar_View_MyName
                }
            }
    
            return ArrangementHeaderViewCellModel(
                nameString: name,
                calendarId: attendee.calendarId,
                avatar: attendee.avatar,
                timeString: timeInfo?.timeString,
                weekString: timeInfo?.timezoneString,
                showBusyIcon: conflictCalendarIds.contains(calendarId),
                showNotWorkingIcon: notWorkingCalendarIds.contains(calendarId),
                hasNoPermission: privateCalMap[calendarId] ?? false,
                timeInfoHidden: timezoneMap[calendarId]?.isEmpty ?? false,
                atLight: sunStateService.isLight(city: timezoneMap[attendee.calendarId] ?? TimeZone.current.identifier, date: Int64(startTime.timeIntervalSince1970))
            )
        }
    }
}
