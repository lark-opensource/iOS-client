//
//  GroupFreeBusyModel.swift
//  Calendar
//
//  Created by sunxiaolei on 2019/7/28.
//

import UIKit
import Foundation
import CalendarFoundation
import LarkContainer
import RustPB

struct GroupFreeBusyModel: ArrangementViewProtocol, FreebusyCalculation, WorkingHoursCalculation {
    
    let chatId: String
    var timezoneMap: [String: String] = [:]
    var privateCalMap: [String: Bool] = [:]
    var is12HourStyle: Bool
    private var workHourSettingMap: WorkHourMap = [:]
    var workHourConflictCalendarIds: [String] {
        return getWorkHourConflictCalendarIds(startTime: startTime,
                                              endTime: endTime,
                                              workingHoursTimeRangeMap: workingHoursTimeRangeMap,
                                              timeZoneId: getTimeZone().identifier)
    }

    var attendees: [CalendarEventAttendeeEntity] = []

    var usersRestrictedForNewEvent: [String] = []

    var startTime: Date

    var endTime: Date

    var firstWeekday: DaysOfWeek

    var calendarInstanceMap: InstanceMap = [:]

    var workingHoursTimeRangeMap: [String: [WorkingHoursTimeRange]] {
        return getWorkingHousTimeRangsMap(date: startTime,
                                          workHourSettingMap: workHourSettingMap,
                                          timezoneMap: timezoneMap, uiTimeZoneId: getTimeZone().identifier)
    }

    var calendarIds: [String] {
        return attendees.map { $0.attendeeCalendarId }
    }

    let sunStateService: SunStateService

    var headerViewModel: ArrangementHeaderViewModel {
        let calendarIds = freeBusyInfo.map { info in
            (info.busyAttendees + info.maybeFreeAttendees)
                .map { $0.calendarId }
        } ?? []
        return ArrangementHeaderViewModel(
            attendees: attendees.map { UserAttendeeBaseDisplayInfo(fromDetail: $0) },
            startTime: startTime,
            timezoneMap: timezoneMap,
            privateCalMap: privateCalMap,
            conflictCalendarIds: calendarIds,
            notWorkingCalendarIds: workHourConflictCalendarIds,
            is12HourStyle: is12HourStyle,
            sunStateService: sunStateService
        )
    }
    var footerViewModel: ArrangementFooterViewModel

    var freeBusyInfo: AttendeeFreeBusyInfo? {
        return opt_calculationFreeBusyInfo(startTime: startTime,
                                           endTime: endTime,
                                           calendarInstanceMap: calendarInstanceMap,
                                           attendees: attendees.map { UserAttendeeBaseDisplayInfo(fromDetail: $0) },
                                           privateCalendarIds: Array(privateCalMap.keys))
    }

    private var groupChatTz: GroupChatTimeZone?

    func cellWidth(with rullerWidth: CGFloat, totalWidth: CGFloat) -> CGFloat {
        let count = attendees.count
        let maxCellCntPerScreen = count >= 5 ? 5 : count
        return (totalWidth - rullerWidth) / CGFloat(maxCellCntPerScreen)
    }
    
    init(sunStateService: SunStateService,
         chatId: String,
         startTime: Date,
         endTime: Date,
         firstWeekday: DaysOfWeek,
         is12HourStyle: Bool) {
        self.chatId = chatId
        self.firstWeekday = firstWeekday
        self.startTime = startTime
        self.endTime = endTime
        self.is12HourStyle = is12HourStyle
        self.sunStateService = sunStateService
        self.footerViewModel = ArrangementFooterViewModel(
            startTime: startTime,
            endTime: endTime,
            totalAttendeeCnt: 0,
            unAvailableAttendeeNames: [],
            hasNotWorkingHours: false,
            textMaxWidth: ArrangementFooterView.labelMaxWidthNoConfirmButton,
            is12HourStyle: is12HourStyle,
            attendeeFreeBusyInfo: AttendeeFreeBusyInfo())
    }

    mutating func changeAttendees(attendees: [CalendarEventAttendeeEntity]) {
        self.attendees = attendees
        self.calendarInstanceMap = [:]
    }

    mutating func changeServerData(_ serverInstanceData: ServerInstanceData) {
        self.calendarInstanceMap = serverInstanceData.instanceMap
        self.timezoneMap = serverInstanceData.timezoneMap
        self.workHourSettingMap = serverInstanceData.workHourMap
        self.privateCalMap = serverInstanceData.privateCalMap
        changeFooterFreeBusyInfo(freeBusyInfo: freeBusyInfo)
    }

    private mutating func changeFooterFreeBusyInfo(freeBusyInfo: AttendeeFreeBusyInfo?) {
        if let freeBusyInfo = freeBusyInfo {
            self.footerViewModel.updateTime(startTime: calibrationDateForUI(date: startTime), endTime: calibrationDateForUI(date: endTime))
            self.footerViewModel.updateSubTitle(
                hasNotWorkingHours: !workHourConflictCalendarIds.isEmpty,
                workingHourConflictCount: workHourConflictCalendarIds.count,
                attendeeFreeBusyInfo: freeBusyInfo)
        } else {
            // 无ui操作仅为状态变量更改
            self.footerViewModel.showFailure(startTime: calibrationDateForUI(date: startTime), endTime: calibrationDateForUI(date: endTime))
        }
    }

    mutating func changeTimeRange(by date: Date) {
        let date = calibrationDate(date: date)
        let (start, end) = getArrangementTimeFordate(date)
        changeTimeRangeInternal(startTime: start, endTime: end)
    }

    mutating func changeTimeRange(startTime: Date, endTime: Date) {
        let startTime = calibrationDate(date: startTime)
        let endTime = calibrationDate(date: endTime)
        changeTimeRangeInternal(startTime: startTime, endTime: endTime)
    }

    private mutating func changeTimeRangeInternal(startTime: Date, endTime: Date) {
        self.startTime = startTime
        self.endTime = endTime
        footerViewModel.updateTime(startTime: calibrationDateForUI(date: startTime), endTime: calibrationDateForUI(date: endTime))
        changeFooterFreeBusyInfo(freeBusyInfo: freeBusyInfo)
    }

    mutating func moveAttendeeToFirst(indexPath: IndexPath) {
        if attendees.indices.contains(indexPath.row) {
            let attendee = attendees.remove(at: indexPath.row)
            attendees.insert(attendee, at: 0)
        }
    }

    func getArrangementTimeFordate(_ date: Date) -> (Date, Date) {

        guard let startDate = TimeZoneUtil.changeDateDay(srcDay: startTime, tzId: getTimeZone().identifier, destDay: date),
            let endDate = TimeZoneUtil.changeDateDay(srcDay: endTime, tzId: getTimeZone().identifier, destDay: date) else {
                                        assertionFailureLog()
                                        return (date, date)
        }
        return (startDate, endDate)
    }

    func getUiStartTime() -> Date {
        return calibrationDateForUI(date: startTime)
    }

    func getUiEndTime() -> Date {
        return calibrationDateForUI(date: endTime)
    }
}
extension GroupFreeBusyModel {

    func getTimeZone() -> TimeZoneModel {
        if let groupChatTz = self.groupChatTz, groupChatTz.chatId == chatId {
            return groupChatTz.timeZone
        } else {
            return TimeZone.current
        }
    }

    func getTzDisplayName() -> String {
        getTimeZone().getGmtOffsetDescription(date: self.startTime)
    }

    mutating func updateTzInfo(chatId: String, timeZone: TimeZoneModel) {
        let oldTz = getTimeZone().identifier
        groupChatTz = GroupChatTimeZone(chatId: chatId, timeZone: timeZone)
    }

    func calibrationDate(date: Date) -> Date {
        // 这里的date是设备时区的date，需要转成年月日时分秒后再转成设置时区的date
        guard TimeZone.current.identifier != getTimeZone().identifier else {
            return date
        }
        return TimeZoneUtil.dateTransForm(srcDate: date, srcTzId: TimeZone.current.identifier, destTzId: getTimeZone().identifier)
    }

    func calibrationDateForUI(date: Date) -> Date {
        // 这里的date是设备时区的date，需要转成年月日时分秒后再转成设置时区的date
        guard TimeZone.current.identifier != getTimeZone().identifier else {
            return date
        }
        return TimeZoneUtil.dateTransForm(srcDate: date, srcTzId: getTimeZone().identifier, destTzId: TimeZone.current.identifier)
    }

    func getUiCurrentDate() -> Date {
     return calibrationDateForUI(date: Date())
    }
}

struct GroupChatTimeZone {
    var chatId: String
    var timeZone: TimeZoneModel
}
