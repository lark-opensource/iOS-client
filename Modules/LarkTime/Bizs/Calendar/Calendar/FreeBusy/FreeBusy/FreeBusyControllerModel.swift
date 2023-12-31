//
//  FreeBusyModel.swift
//  Calendar
//
//  Created by zhouyuan on 2019/4/8.
//

import UIKit
import UniverseDesignIcon
import Foundation
import CalendarFoundation
import UniverseDesignColor

struct FreeBusyControllerModel: FreebusyCalculation, WorkingHoursCalculation {

    var startTime: Date = Date()
    var endTime: Date = Date()
    let currentUserCalendarId: String
    var timezoneMap: [String: String] = [:]
    var privateCalMap: [String: Bool] = [:]
    var calendarInstanceMap: InstanceMap = [:]
    var footerAttrText: NSAttributedString? {
        if let info = opt_calculationFreeBusyInfo(startTime: startTime,
                                                   endTime: endTime,
                                                   calendarInstanceMap: calendarInstanceMap,
                                                   attendees: attendees.map { UserAttendeeBaseDisplayInfo(fromDetail: $0) },
                                                   privateCalendarIds: Array(privateCalMap.keys)) {
            if workHourConflictCalendarIds.isEmpty {
                let text = ArrangementFreeBusyTextUtil.textWithoutWorkingHour(with: info)
                return text.attributedText(with: ArrangementFooterViewModel.subTitleFont, color: ArrangementFreeBusyTextUtil.textColor(with: info))
            }
            let text = ArrangementFreeBusyTextUtil.textOnWorkingHour(with: info)
            return text.attributedText(with: ArrangementFooterViewModel.subTitleFont, color: UDColor.textPlaceholder)
        } else {
            return getFooterAttrText(isFreeBusyConflict: !getFreeBusyConflictcalendarIds().isEmpty,
                                     isWorkHourConflict: !workHourConflictCalendarIds.isEmpty,
                                     workHourConflictCount: workHourConflictCalendarIds.count, unAvailableAttendeeCount: getFreeBusyConflictcalendarIds().count)
        }
    }
    var attendees: [CalendarEventAttendeeEntity] = []
    var usersRestrictedForNewEvent: [String] = []
    var is12HourStyle: Bool
    var calendarIds: [String] {
        return attendees.map { $0.attendeeCalendarId }
    }
    var currentDate: Date = Date()

    let sunStateService: SunStateService

    var headerViewModel: ArrangementHeaderViewModel {
        return ArrangementHeaderViewModel(
                attendees: attendees.map { UserAttendeeBaseDisplayInfo(fromDetail: $0) },
                startTime: startTime,
                timezoneMap: timezoneMap,
                privateCalMap: privateCalMap,
                conflictCalendarIds: getFreeBusyConflictcalendarIds(),
                notWorkingCalendarIds: workHourConflictCalendarIds,
                currentUserCalendarId: currentUserCalendarId,
                is12HourStyle: is12HourStyle,
                sunStateService: sunStateService
            )
    }

    private var workHourSettingMap: WorkHourMap = [:]
    func workingHoursTimeRangeMap(date: Date) -> [String: [WorkingHoursTimeRange]] {
        return getWorkingHousTimeRangsMap(date: date,
                                          workHourSettingMap: workHourSettingMap,
                                          timezoneMap: timezoneMap, uiTimeZoneId: timeZone.identifier)
    }

    var workHourConflictCalendarIds: [String] {
        return getWorkHourConflictCalendarIds(
            startTime: startTime,
            endTime: endTime,
            workingHoursTimeRangeMap: workingHoursTimeRangeMap(date: startTime),
            timeZoneId: getTimeZone().identifier
        )
    }

    var timeZone: TimeZoneModel

    init(sunStateService: SunStateService,
         currentUserCalendarId: String,
         is12HourStyle: Bool) {
        self.sunStateService = sunStateService
        self.currentUserCalendarId = currentUserCalendarId
        self.is12HourStyle = is12HourStyle
        let sortedAttendees = FreeBusyControllerModel
            .sortedAttendees(attendees: attendees, calendarId: currentUserCalendarId)
        self.attendees = sortedAttendees
        self.timeZone = TimeZone.current
    }

    /// 自己排在后面
    static func sortedAttendees(attendees: [CalendarEventAttendeeEntity],
                                calendarId: String) -> [CalendarEventAttendeeEntity] {
        var attendees = attendees
        if let index = attendees.firstIndex(where: { $0.attendeeCalendarId == calendarId }) {
            let attendee = attendees.remove(at: index)
            attendees.append(attendee)
        }
        return attendees
    }

    mutating func changeIs12HourStyle(is12HourStyle: Bool) {
        self.is12HourStyle = is12HourStyle
    }

    mutating func changeAttendees(attendees: [CalendarEventAttendeeEntity]) {
        let sortedAttendees = FreeBusyControllerModel
            .sortedAttendees(attendees: attendees, calendarId: currentUserCalendarId)
        self.attendees = sortedAttendees
    }

    mutating func changetimezoneMap(_ timezoneMap: [String: String]) {
        self.timezoneMap = timezoneMap
    }

    mutating func changeWorkHourSettingMap(_ workHourSettingMap: WorkHourMap) {
        self.workHourSettingMap = workHourSettingMap
    }

    mutating func changeTime(startTime: Date, endTime: Date) {
        if startTime.timeString() == endTime.timeString() {
            changeTimeInternal(startTime: startTime, endTime: endTime)
            return
        }
        let startTime = calibrationDate(date: startTime)
        let endTime = calibrationDate(date: endTime)
        changeTimeInternal(startTime: startTime, endTime: endTime)
    }

    mutating private func changeTimeInternal(startTime: Date, endTime: Date) {
        self.startTime = startTime
        self.endTime = endTime
    }

    mutating func changeInstanceMap(calendarInstanceMap: InstanceMap) {
        self.calendarInstanceMap = calendarInstanceMap
    }

    func getFreeBusyConflictcalendarIds() -> [String] {
        let info = calculationFreeBusyInfo(startTime: startTime,
                                           endTime: endTime,
                                           calendarInstanceMap: calendarInstanceMap,
                                           attendees: attendees.map { UserAttendeeBaseDisplayInfo(fromDetail: $0) })
        return info?.calendarIds ?? []
    }

    /// 会议室忙闲计算当前可用的最早时间段 调用之前先确认下场景？
    /// - Returns: 可用时间段的 startTime/endTime
    func earliestAvailableDuration() -> Range<Date> {
        guard startTime < endTime else { return Date()..<Date() }

        // 在会议室忙闲中 可以认为所有日程不会出现重叠 先开始的日程必然先结束
        let allInstances: [Range<Date>] = Array(calendarInstanceMap.values.joined().map({ $0.startDate ..< $0.endDate })).sorted { $0.lowerBound < $1.lowerBound }

        // 处理处理 duration 和 instance 在不同情况下的新 duration
        func process<T>(_ duration: Range<T>, _ instance: Range<T>) -> Range<T> {
            if duration.overlaps(instance) {
                if instance.isSubRange(of: duration) {
                    return duration.lowerBound ..< instance.lowerBound
                } else if duration.contains(instance.upperBound) {
                    return instance.upperBound ..< duration.upperBound
                } else if duration.contains(instance.lowerBound) {
                    return duration.lowerBound ..< instance.lowerBound
                } else {
                    return duration.lowerBound ..< duration.lowerBound
                }
            } else {
                return duration
            }
        }

        return allInstances.reduce(startTime ..< endTime, process(_:_:))
    }

    /// 根据冲突 instance 的类型给出精细化的 toast 文案
    /// - Parameter oriEventRange: 未经计算的日程 range
    /// - Returns: 冲突 toast 文案
    func meetingRoomConflictReason(with oriEventRange: Range<Date>) -> String? {
        guard let conflictType = calendarInstanceMap.values.joined()
                .first { oriEventRange.overlaps($0.startDate..<$0.endDate) }?.meetingRoomCategory else { return nil }
        switch conflictType {
        case .resourceStrategy:
            return BundleI18n.Calendar.Calendar_Edit_MeetingRoomCantBeReserved
        case .resourceRequisition:
            return BundleI18n.Calendar.Calendar_MeetingRoom_ReservationBanned
        @unknown default:
            return BundleI18n.Calendar.Calendar_MeetingRoom_SomeoneAlreadyReserved
        }
    }

    private func getFooterAttrText(isFreeBusyConflict: Bool, isWorkHourConflict: Bool, workHourConflictCount: Int, unAvailableAttendeeCount: Int) -> NSAttributedString? {
        if !isFreeBusyConflict && !isWorkHourConflict {
            return nil
        }

        let result = NSMutableAttributedString()
        let title: NSAttributedString
        let numOfOnBusyGuests = workHourConflictCount | unAvailableAttendeeCount
        let numOfOnBusyGuestsText = BundleI18n.Calendar.Calendar_Plural_GuestOnBusy(number: numOfOnBusyGuests)
        title = "\(numOfOnBusyGuestsText) ".attributedText(with: ArrangementFooterViewModel.subTitleFont,
                                               color: UIColor.ud.N600)
        result.append(title)

        // 只有工作时间的冲突
        if !isFreeBusyConflict {
            result.append(ArrangementFooterViewModel.getAttachmentText(image: UDIcon.getIconByKeyNoLimitSize(.workTimeColorful), endString: BundleI18n.Calendar.Calendar_Workinghours_Notworking))
            return result
        }

        /// 下面是处理忙闲冲突逻辑

        // 忙闲冲突中带有工作时间的冲突, 在前面插入一段工作时间冲突的文案
        if isWorkHourConflict {
            let notworkingText = ArrangementFooterViewModel.getAttachmentText(image: UDIcon.getIconByKeyNoLimitSize(.workTimeColorful), endString: "\(BundleI18n.Calendar.Calendar_Workinghours_Notworking)/")
            result.append(notworkingText)
        }

        // 这是忙闲冲突的文案
        let busyText = ArrangementFooterViewModel.getAttachmentText(image: UDIcon.getIconByKeyNoLimitSize(.conflictColorful), endString: BundleI18n.Calendar.Calendar_Detail_Busy)
        result.append(busyText)
        return result
    }
}
extension FreeBusyControllerModel {

    func getTimeZone() -> TimeZoneModel {
        return timeZone
    }

   mutating func getTzDisplayName(uiDate: Date? = nil) -> String {
        if let date = uiDate {
            currentDate = calibrationDate(date: date)
        }

        return getTimeZone().getGmtOffsetDescription(date: startTime)
    }

    mutating func updateTzInfo(timeZone: TimeZoneModel) {
        let oldTz = getTimeZone().identifier
        self.timeZone = timeZone
        let startTime = TimeZoneUtil.dateTransForm(srcDate: self.startTime, srcTzId: oldTz, destTzId: timeZone.identifier)
        let endTime = TimeZoneUtil.dateTransForm(srcDate: self.endTime, srcTzId: oldTz, destTzId: timeZone.identifier)
        changeTimeInternal(startTime: startTime, endTime: endTime)
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

private extension Range {
    func isSubRange(of another: Range<Bound>) -> Bool {
        return another.lowerBound < lowerBound && upperBound <= another.upperBound
    }
}
