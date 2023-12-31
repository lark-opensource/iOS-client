//
//  EventEditViewModel+ViewAction.swift
//  Calendar
//
//  Created by 张威 on 2020/3/23.
//

import RxSwift
import RxCocoa
import EventKit
import CalendarFoundation
import LarkLocalizations
import LarkTimeFormatUtils

/// Response ViewAction

extension EventEditViewModel {

    // 同步 summary 到 sdk
    func updateSummary(_ summary: String) {
        guard var event = eventModel?.rxModel?.value,
              event.summary != nil || !summary.isEmpty else { return }
        // 埋点
        if actionState.isChangedTitle == false {
            actionState.isChangedTitle = true
            CalendarTracerV2.EventFullCreate.traceClick {
                $0.click("add_title")
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: eventModel?.rxModel?.value.getPBModel(), startTime: Int64(eventModel?.rxModel?.value.startDate.timeIntervalSince1970 ?? 0)))
            }
        }
        event.summary = summary
        eventModel?.rxModel?.accept(event)
        EventEdit.logger.info("update summary")
    }

    // MARK: Attendee

    func addAttendees(
        type: WebinarAttendeeType? = nil,
        seeds: [EventAttendeeSeed],
        departments: [(id: String, name: String)] = .init(),
        messageReceiver: @escaping (AddAttendeeViewMessage) -> Void
    ) {
        if let type = type {
            webinarAttendeeModel?.addAttendees(type: type, seeds: seeds, departments: departments, messageReceiver: messageReceiver)
        } else {
            attendeeModel?.addAttendees(withSeeds: seeds, departments: departments, messageReceiver: messageReceiver)
            EventEdit.logger.info("add attendee seeds: \(seeds.map { $0.debugDescription })")
        }
    }

    func updateAttendees(attendees: [EventEditAttendee], simpleAttendees: [Rust.IndividualSimpleAttendee], attendeeType: AttendeeType) {
        switch attendeeType {
        case .webinar(let webinarAttendeeType):
            webinarAttendeeModel?.resetAttedees(attendees: attendees, simpleAttendees: simpleAttendees, type: webinarAttendeeType)
        case .normal:
            attendeeModel?.resetAttedees(attendees: attendees, simpleAttendees: simpleAttendees)
        }
        EventEdit.logger.info("update attendee: \(attendees.map { $0.debugDescription })")
        CalendarTracerV2.EventFullCreate.traceClick {
            $0.click("delete_attendee")
            $0.is_new_create = input.isFromCreating ? "true" : "false"
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: eventModel?.rxModel?.value.getPBModel(), startTime: Int64(eventModel?.rxModel?.value.startDate.timeIntervalSince1970 ?? 0)))
        }
    }

    func waitAttendeesLoading(onSuccess: @escaping (() -> Void),
                              onFailure: @escaping (() -> Void)) {
        attendeeModel?.waitAllAttendees(onSuccess: onSuccess,
                                         onFailure: onFailure)
    }

    // MARK: GuestPermssion
    func updateGuestPermission(_ permission: GuestPermission) {
        guard var event = eventModel?.rxModel?.value else { return }
        let guestCanModify = permission >= .guestCanModify
        let guestCanInvite = permission >= .guestCanInvite
        let guestCanSeeOtherGuests = permission >= .guestCanSeeOtherGuests

        event.guestCanModify = guestCanModify
        event.guestCanInvite = guestCanInvite
        event.guestCanSeeOtherGuests = guestCanSeeOtherGuests

        eventModel?.rxModel?.accept(event)
        EventEdit.logger.info("update guest permission")
    }

    // MARK: Meeting Notes Config
    func updateCreateNotesPermission(_ permission: Rust.CreateNotesPermission) {
        guard var event = eventModel?.rxModel?.value else { return }
        event.meetingNotesConfig.createNotesPermission = permission
        eventModel?.rxModel?.accept(event)
        EventEdit.logger.info("update create notes permission: \(permission.rawValue)")
    }

    // MARK: Date

    func updateDateComponents(
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        timeZone: TimeZone = .current
    ) {
        guard var event = eventModel?.rxModel?.value else { return }

        let isAllDayChanged = (isAllDay != event.isAllDay)
        let oldStartDate = event.startDate
        let isChangeDate = (event.startDate != startDate) || (event.endDate != endDate)
        let isChangeTimezone = timeZone != event.timeZone
        event.startDate = startDate
        event.endDate = endDate
        event.isAllDay = isAllDay
        event.timeZone = timeZone

        // 非全天 <-> 全天，根据 settings 重置 reminders
        if isAllDayChanged {
            if isAllDay, let reminder = setting.allDayReminder {
                event.reminders = [EventEditReminder(minutes: reminder.minutes)]
            } else if !isAllDay, let reminder = setting.noneAllDayReminder {
                event.reminders = [EventEditReminder(minutes: reminder.minutes)]
            } else {
                event.reminders = []
            }
        }

        // 非全天 <-> 全天，重置忙/闲
        if isAllDayChanged {
            event.freeBusy = isAllDay ? .free : .busy
        }

        // 根据 startDate 调整 rrule 的截止时间
        if var rrule = event.rrule {
            rrule = adjustedWeekdays(ofRrule: rrule, fromStartDate: oldStartDate, toStartDate: event.startDate)
            rrule = adjustedMonthDays(ofRrule: rrule, fromStartDate: oldStartDate, toStartDate: event.startDate)
            event.rrule = rrule
        }

        eventModel?.rxModel?.accept(event)
        if isChangeDate {
            // 埋点
            CalendarTracerV2.EventFullCreate.traceClick {
                $0.click("save_time")
                $0.is_time_alias = "true"
                $0.event_type = input.isWebinarScene ? "webinar" : "normal"
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: eventModel?.rxModel?.value.getPBModel(), startTime: Int64(eventModel?.rxModel?.value.startDate.timeIntervalSince1970 ?? 0)))
            }
        }
        if isChangeTimezone {
            // 埋点
            CalendarTracerV2.EventFullCreate.traceClick {
                $0.click("change_timezone")
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: eventModel?.rxModel?.value.getPBModel(), startTime: Int64(eventModel?.rxModel?.value.startDate.timeIntervalSince1970 ?? 0)))
            }
        }
        EventEdit.logger.info(
            "update date components. {startDate: \(startDate), endDate: \(endDate), isAllDay: \(isAllDay), timeZone: \(timeZone.identifier)}"
        )
    }

    // MARK: - VideoMeeting
    func updateVideoMeeting(_ videoMeeting: Rust.VideoMeeting, zoomConfig: Rust.ZoomVideoMeetingConfigs? = nil) {
        guard var event = eventModel?.rxModel?.value else { return }
        event.videoMeeting = videoMeeting
        self.localZoomConfigs = zoomConfig
        eventModel?.rxModel?.accept(event)
    }

    func getVideoMeeting() -> Rust.VideoMeeting? {
        guard var event = eventModel?.rxModel?.value else { return nil }
        return event.videoMeeting
    }

    // MARK: - Calendar

    func updateCalendar(_ calendar: EventEditCalendar) {
        guard let prevCalendar = self.calendarModel?.rxModel?.value.current else {
            assertionFailure()
            return
        }
        // 埋点
        CalendarTracerV2.EventFullCreate.traceClick {
            $0.click("change_calendar")
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: eventModel?.rxModel?.value.getPBModel(), startTime: Int64(eventModel?.rxModel?.value.startDate.timeIntervalSince1970 ?? 0)))
        }
        self.calendarModel?.rxModel?.accept((prevCalendar, calendar))

        EventEdit.logger.info("update calendar. calendarId: \(calendar.id)")
    }

    // MARK: Color

    func updateColor(_ color: ColorIndex) {
        guard var event = eventModel?.rxModel?.value else { return }
        event.customizedColor = color
        eventModel?.rxModel?.accept(event)
    }

    // MARK: Visibility

    func updateVisibility(_ visibility: EventVisibility) {
        guard var event = eventModel?.rxModel?.value else { return }
        event.visibility = visibility
        eventModel?.rxModel?.accept(event)

        EventEdit.logger.info("update visibility: \(visibility)")
    }

    // MARK: FreeBusy

    func updateFreeBusy(_ freeBusy: EventFreeBusy) {
        guard var event = eventModel?.rxModel?.value else { return }
        event.freeBusy = freeBusy
        eventModel?.rxModel?.accept(event)

        EventEdit.logger.info("update freeBusy: \(freeBusy)")
    }

    // MARK: Expand
    func updateExpand(_ expand: Bool) {
        expandModel?.rxModel?.accept(expand)
    }

    // MARK: Reminder

    func updateReminders(_ reminders: [EventEditReminder]) {
        guard var event = eventModel?.rxModel?.value else { return }
        // 埋点
        CalendarTracerV2.EventFullCreate.traceClick {
            $0.click("change_reminder_time")
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: eventModel?.rxModel?.value.getPBModel(), startTime: Int64(eventModel?.rxModel?.value.startDate.timeIntervalSince1970 ?? 0)))
        }
        event.reminders = reminders.sorted(by: { $0.minutes < $1.minutes })
        eventModel?.rxModel?.accept(event)

        EventEdit.logger.info("update reminders: \(reminders.map { $0.debugDescription })")
    }

    func clearReminders() {
        guard var event = eventModel?.rxModel?.value else { return }
        event.reminders = []
        eventModel?.rxModel?.accept(event)

        EventEdit.logger.info("clear reminders")
    }

    // MARK: Rrule

    // 自定义周x重复，更改开始时间后，自动更改rrule，去掉old startTime所在周X，添加new startTime所在周X
    private func adjustedWeekdays(
        ofRrule rrule: EventRecurrenceRule,
        fromStartDate: Date,
        toStartDate: Date
    ) -> EventRecurrenceRule {
        guard var daysOfWeek = rrule.daysOfTheWeek,
            !daysOfWeek.isEmpty,
            fromStartDate.weekday != toStartDate.weekday else {
            return rrule
        }
        guard let weekday = EKWeekday(rawValue: toStartDate.weekday) else {
            return rrule
        }
        var needsWeekNumber = false
        if let weekNumber = daysOfWeek.first(where: { $0.dayOfTheWeek.rawValue == fromStartDate.weekday })?.weekNumber,
            weekNumber > 0 {
            needsWeekNumber = true
        }
        daysOfWeek.removeAll(where: { $0.dayOfTheWeek.rawValue == fromStartDate.weekday })
        let dayOfWeek: EKRecurrenceDayOfWeek
        if needsWeekNumber {
            let weekNumber = toStartDate.weekOfMonth
            dayOfWeek = EKRecurrenceDayOfWeek(dayOfTheWeek: weekday, weekNumber: weekNumber)
        } else {
            dayOfWeek = EKRecurrenceDayOfWeek(weekday)
        }
        if !daysOfWeek.contains(where: { $0.dayOfTheWeek == dayOfWeek.dayOfTheWeek }) {
            daysOfWeek.append(dayOfWeek)
        }
        return EventRecurrenceRule(
            recurrenceWith: rrule.frequency,
            interval: rrule.interval,
            daysOfTheWeek: daysOfWeek,
            daysOfTheMonth: rrule.daysOfTheMonth,
            monthsOfTheYear: rrule.monthsOfTheYear,
            weeksOfTheYear: rrule.weeksOfTheYear,
            daysOfTheYear: rrule.daysOfTheYear,
            setPositions: rrule.setPositions,
            end: rrule.recurrenceEnd
        )
    }

    // 自定义每月x重复，更改开始时间后，自动更改rrule，去掉old startTime所在x日，添加new startTime所在周x
    private func adjustedMonthDays(
        ofRrule rrule: EventRecurrenceRule,
        fromStartDate: Date,
        toStartDate: Date
    ) -> EventRecurrenceRule {
        guard var daysOfMonth = rrule.daysOfTheMonth,
            !daysOfMonth.isEmpty,
            fromStartDate.day != toStartDate.day else {
            return rrule
        }
        daysOfMonth.removeAll(where: { $0.intValue == fromStartDate.day })
        let monthDay = NSNumber(value: toStartDate.day)
        if !daysOfMonth.contains(where: { $0.intValue == monthDay.intValue }) {
            daysOfMonth.append(monthDay)
        }
        return EventRecurrenceRule(
            recurrenceWith: rrule.frequency,
            interval: rrule.interval,
            daysOfTheWeek: rrule.daysOfTheWeek,
            daysOfTheMonth: daysOfMonth,
            monthsOfTheYear: rrule.monthsOfTheYear,
            weeksOfTheYear: rrule.weeksOfTheYear,
            daysOfTheYear: rrule.daysOfTheYear,
            setPositions: rrule.setPositions,
            end: rrule.recurrenceEnd
        )
    }

    // 自动限制 rrule 的截止时间。如果日程有会议室，则 rrule 截止时间需要限制
    @discardableResult
    private func limitEndDateIfNeeded(for rrule: EventRecurrenceRule) -> Bool {
        guard permissionModel?.rxPermissions.value.rrule.isEditable ?? false,
              let (_, maxEndDate) = meetingRoomMaxEndDateInfo(),
              let eventModel = eventModel?.rxModel?.value else { return false }

        if let rruleEndDate = eventModel.rrule?.recurrenceEnd?.endDate {
            if rruleEndDate.dayEnd() > maxEndDate {
                rrule.recurrenceEnd = EKRecurrenceEnd(end: maxEndDate)
                return true
            }
        } else {
            rrule.recurrenceEnd = EKRecurrenceEnd(end: maxEndDate)
            return true
        }
        return false
    }

    func adjustRruleEndDate() {
        guard let event = eventModel?.rxModel?.value,
              let rrule = event.rrule else {
            return
        }
        guard limitEndDateIfNeeded(for: rrule) else {
            assertionFailure()
            return
        }
        eventModel?.rxModel?.accept(event)
    }

    func updateRrule(_ rrule: EventRecurrenceRule?) {
        guard var event = eventModel?.rxModel?.value else { return }
        event.rrule = rrule
        eventModel?.rxModel?.accept(event)
        EventEdit.logger.info("update rrule: \(rrule.debugDescription)")
    }

    // MARK: Location

    func updateLocation(_ location: EventEditLocation?) {
        guard var event = eventModel?.rxModel?.value else { return }
        event.location = location
        eventModel?.rxModel?.accept(event)
        // 埋点
        CalendarTracerV2.EventFullCreate.traceClick {
            $0.click("add_location")
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: eventModel?.rxModel?.value.getPBModel(), startTime: Int64(eventModel?.rxModel?.value.startDate.timeIntervalSince1970 ?? 0)))
        }
        EventEdit.logger.info("update location")
    }

    // MARK: CheckIn

    func updateCheckIn(_ checkIn: Rust.CheckInConfig) {
        guard var event = eventModel?.rxModel?.value else { return }

        event.checkInConfig = checkIn
        eventModel?.rxModel?.accept(event)

        EventEdit.logger.info("update checkIn")
    }

    func closeCheckIn() {
        guard var event = eventModel?.rxModel?.value else { return }

        event.checkInConfig.checkInEnable = false
        eventModel?.rxModel?.accept(event)

        EventEdit.logger.info("close checkIn")
    }

    // MARK: MeetingRoom

    func confirmAlertTextsForDeletingMeetingRoom(
        _ meetingRoom: CalendarMeetingRoom
    ) -> EventEditConfirmAlertTexts? {
        guard let alertMessage = meetingRoomModel?.alertMessageForRemovingMeetingRoom(meetingRoom) else {
            return nil
        }
        return EventEditConfirmAlertTexts(message: alertMessage)
    }

    func confirmAlertTextsForDeletingVisibleMeetingRoom(at index: Int) -> EventEditConfirmAlertTexts? {
        guard let meetingRoom = meetingRoomModel?.visibleMeetingRoom(at: index) else {
            assertionFailure()
            return nil
        }
        return confirmAlertTextsForDeletingMeetingRoom(meetingRoom)
    }

    func addMeetingRooms(_ meetingRooms: [CalendarMeetingRoom]) {
        meetingRoomModel?.addMeetingRooms(meetingRooms)
        attendeeModel?.updateAttendeeIfNeeded(forMeetingRoomsAdded: meetingRooms)
        webinarAttendeeModel?.updateAttendeeIfNeeded(forMeetingRoomsAdded: meetingRooms, type: .speaker)
        EventEdit.logger.info("addMeetingRoom: \(meetingRooms.map { $0.uniqueId })")
    }

    func deleteMeetingRoom(byId id: String) {
        meetingRoomModel?.removeMeetingRoom(byId: id)
        EventEdit.logger.info("deleteMeetingRoomById: \(id)")
    }

    func deleteMeetingRoom(at index: Int) {
        meetingRoomModel?.removeVisibleMeetingRoom(at: index)
        EventEdit.logger.info("deleteMeetingRoom at index: \(index), \(meetingRoomModel?.visibleMeetingRooms().map { $0.uniqueId })")
    }

    func meetingRoomForm(index: Int) -> Rust.ResourceCustomization? {
        meetingRoomModel?.meetingRoomForm(index: index)
    }

    func meetingRoomUpdateForm(index: Int, newForm: Rust.ResourceCustomization) {
        meetingRoomModel?.updateForm(index: index, newForm: newForm)
    }

    // MARK: Notes

    func clearNotes() {
        notesModel?.clearNotes()
        EventEdit.logger.info("clearNotes")
    }

    func updateNotes(_ notes: EventNotes) {
        notesModel?.updateNotes(notes)
        EventEdit.logger.info("updateNotes")
        CalendarTracerV2.EventFullCreate.traceClick {
            $0.click("edit_description")
            $0.event_type = input.isWebinarScene ? "webinar" : "normal"
            $0.is_new_create = input.isFromCreating ? "true" : "false"
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: eventModel?.rxModel?.value.getPBModel(), startTime: Int64(eventModel?.rxModel?.value.startDate.timeIntervalSince1970 ?? 0)))
        }
    }

    // MARK: MeetingNotes
    /// 删除 MeetingNotes
    func deleteMeetingNotes() {
        meetingNotesModel?.deleteMeetingNotes(.currentNotes)
        EventEdit.logger.info("delete meeting notes")
    }

    /// 通过模版创建 MeetingNotes
    func createMeetingNotes(by template: CalendarTemplateItem?) -> Observable<(MeetingNotesModel?, Bool)> {
        EventEdit.logger.info("create meeting notes")
        guard let meetingNotesModel = meetingNotesModel,
              let event: EventEditModel = eventModel?.rxModel?.value else {
            return .empty()
        }
        let title = MeetingNotesLoader.makeDocTitle(
            templateTitle: template?.name ?? "",
            eventSummary: event.summary ?? "",
            date: event.startDate,
            timeZone: event.timeZone)
        return meetingNotesModel.createMeetingNotes(by: template,
                                                    title: title)
    }

    /// 关联文档
    func associateMeetingNotes(token: String, type: Int) -> Observable<MeetingNotesModel?> {
        EventEdit.logger.info("bind meeting notes")
        guard let meetingNotesModel = meetingNotesModel else { return .empty() }
        return meetingNotesModel.associateMeetingNotes(token: token, type: type)
    }

    /// 1. 获取模版列表第一个模版
    /// 2. 通过模版创建 MeetingNotes
    /// 已废弃，暂时保留，后续下掉
    func fetchTemplateListAndCreate() -> Observable<(MeetingNotesModel?, Bool)> {
        EventEdit.logger.info("fetch template and create meeting notes")
        guard let meetingNotesModel = meetingNotesModel else { return .empty() }
        return meetingNotesModel.fetchTemplateList()
            .flatMap { [weak self] template -> Observable<(MeetingNotesModel?, Bool)> in
                return self?.createMeetingNotes(by: template) ?? .empty()
            }
    }

    // MARK: Close

    // 关闭退出编辑的 tip alert
    func alertTipForClosing(trace: CalendarTracerV2.EventCreateCancelConfirm.ViewParams) -> (String?, String?)? {
        guard let eventModelBeforeEditing = eventModelBeforeEditing,
              let event = eventModel?.rxModel?.value else { return nil }
        let tip: (String?, String?) = (I18n.Calendar_Edit_QuitPop, I18n.Calendar_Edit_QuitPopNoteShort)
        let (fromModel, toModel) = (eventModelBeforeEditing, event)

        if let meetingNotesModel = meetingNotesModel,
           meetingNotesModel.notesHasEdit {
            if let notes = meetingNotesModel.currentNotes,
               notes.notesType == .createNotes {
                trace.will_delete_notes = true.description
                return (tip.0, I18n.Calendar_Edit_QuitPopNote)
            }
            return tip
        }

        if (fromModel.summary ?? "") != (toModel.summary ?? "") { return tip }

        if fromModel.isAllDay != toModel.isAllDay
            || fromModel.startDate.timeIntervalSince1970 != toModel.startDate.timeIntervalSince1970
            || fromModel.endDate.timeIntervalSince1970 != toModel.endDate.timeIntervalSince1970 {
            return tip
        }

        if fromModel.calendar?.id != toModel.calendar?.id { return tip }

        if fromModel.videoMeeting != toModel.videoMeeting { return tip }
//        if !fromModel.videoMeeting.isEqual(to: toModel.videoMeeting) { return tip }

        if fromModel.color != toModel.color { return tip }

        if fromModel.visibility != toModel.visibility { return tip }

        if fromModel.freeBusy != toModel.freeBusy { return tip }

        if fromModel.reminders.map({ $0.minutes }) != toModel.reminders.map({ $0.minutes }) { return tip }

        if (fromModel.location?.name ?? "") != (toModel.location?.name ?? "") ||
            (fromModel.location?.address ?? "") != (toModel.location?.address ?? "") {
            return tip
        }

        if fromModel.attachments.map({ $0.token }) != toModel.attachments.map({ $0.token }) { return tip }

        if fromModel.notes != toModel.notes {
            return tip
        }

        if fromModel.rrule?.iCalendarString() != toModel.rrule?.iCalendarString() {
            return tip
        }

        let meetingDiffInfoTransform = { (m: CalendarMeetingRoom) -> String in "\(m.uniqueId)\(m.status)" }
        if fromModel.meetingRooms.map(meetingDiffInfoTransform) != toModel.meetingRooms.map(meetingDiffInfoTransform) {
            return tip
        }
        
        let attendeeDiffTransform = { (a: EventEditAttendee) -> String in return "\(a.uniqueId)\(a.status)" }
        if input.isFromAI {
            if case .createWithContext(let context) = input {
                let fromIds = context.attendeeSeeds.map {
                    if case .user(let chatterID) = $0 {
                        return chatterID
                    }
                    return ""
                }.filter { !$0.isEmpty }
                
                let toIds = toModel.attendees.map {
                    if case .user(let attendee) = $0 {
                       return attendee.simpleAttendee.user.chatterID
                    }
                    return ""
                }.filter { !$0.isEmpty }
                
                if fromIds != toIds{
                    return tip
                }
            }
        } else {
            if Set(fromModel.attendees.map(attendeeDiffTransform)) != Set(toModel.attendees.map(attendeeDiffTransform)) {
                return tip
            }
        }

        if Set(fromModel.speakers.map(attendeeDiffTransform)) != Set(toModel.speakers.map(attendeeDiffTransform)) {
            return tip
        }

        if Set(fromModel.audiences.map(attendeeDiffTransform)) != Set(toModel.audiences.map(attendeeDiffTransform)) {
             return tip
        }

        if fromModel.checkInConfig != toModel.checkInConfig {
            return tip
        }

        if fromModel.guestCanModify != toModel.guestCanModify ||
            fromModel.guestCanInvite != toModel.guestCanInvite ||
            fromModel.guestCanSeeOtherGuests != toModel.guestCanSeeOtherGuests {
            return tip
        }

        return nil
    }

    // 一键调整被点击
    func autoJustTimeTapped(needRenewalReminder: Bool, rrule: EventRecurrenceRule?) {
        // needRenewalReminder只能从false => true
        if self.needRenewalReminder != true {
            self.needRenewalReminder = needRenewalReminder
        }
        if let rrule = rrule {
            self.updateRrule(rrule)
        }
    }
}
