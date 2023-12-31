//
//  EventEditViewModel+Event.swift
//  Calendar
//
//  Created by ByteDance on 2023/1/16.
//

import Foundation
import CalendarFoundation
import RxCocoa
import RxSwift
import EventKit

// MARK: Setup EventModel
extension EventEditViewModel {

    var eventModel: EventEditModelManager<EventEditModel>? {
        self.models[EventEditModelType.event] as? EventEditModelManager<EventEditModel>
    }

    private func defaultStartDate() -> Date {
        return NewEventModel.formatNewEventTime(Date())
    }

    private func fixedEndDate(
        by referenceDate: Date?,
        startDate: Date,
        isAllDay: Bool
    ) -> Date {
        if let endDate = referenceDate, endDate > startDate {
            return endDate
        }
        return startDate.addingTimeInterval(TimeInterval(Int32(60) * setting.defaultEventDuration))
    }

    func makeEventModel(with input: EventEditInput) -> EventEditModel {
        var eventModel: EventEditModel
        switch input {
        case .createWithContext, .createWebinar:
            eventModel = EventEditModel(category: input.isWebinarScene ? .webinar : .defaultCategory)
            eventModel.startDate = defaultStartDate()
            eventModel.endDate = fixedEndDate(by: nil, startDate: eventModel.startDate, isAllDay: false)
            if case .createWithContext(let createConext) = input {
                eventModel.summary = createConext.summary
                eventModel.startDate = createConext.startDate ?? defaultStartDate()
                eventModel.timeZone = createConext.timeZone
                eventModel.rrule = EKRecurrenceRule.recurrenceRuleFromString(createConext.rrule ?? "")

                let referenceDate = createConext.endDate
                eventModel.endDate = fixedEndDate(
                    by: referenceDate,
                    startDate: eventModel.startDate,
                    isAllDay: createConext.isAllDay
                )
                if createConext.isOpenLarkVC {
                    var videoMeeting = Rust.VideoMeeting()
                    videoMeeting.videoMeetingType = .vchat

                    eventModel.videoMeeting = videoMeeting
                }

                eventModel.meetingRooms = createConext.meetingRooms.map { CalendarMeetingRoom.makeMeetingRoom(fromResource: $0.fromResource, buildingName: $0.buildingName, tenantId: $0.tenantId) }
                eventModel.isAllDay = createConext.isAllDay
            }

            if eventModel.isAllDay {
                if let reminder = setting.allDayReminder {
                    eventModel.reminders = [EventEditReminder(minutes: reminder.minutes)]
                }
            } else {
                if let reminder = setting.noneAllDayReminder {
                    eventModel.reminders = [EventEditReminder(minutes: reminder.minutes)]
                }
            }
        case .editFrom(let pbEvent, let pbInstance), .editWebinar(pbEvent: let pbEvent, pbInstance: let pbInstance):
            eventModel = EventEditModel(from: pbEvent, instance: pbInstance)
            let timeZone: TimeZone
            if !pbInstance.startTimezone.isEmpty,
                let tz = TimeZone(identifier: pbInstance.startTimezone) {
                timeZone = tz
            } else {
                if eventModel.isAllDay {
                    // 全天日程的时区默认为 UTC/GMT
                    timeZone = TimeZone(identifier: "GMT") ?? TimeZone(secondsFromGMT: 0) ?? .current
                } else {
                    timeZone = .current
                }
            }
            eventModel.timeZone = timeZone
        case .editFromLocal(let ekEvent):
            eventModel = EventEditModel.makeFromEKEvent(ekEvent)
        case .copyWithEvent(let pbEvent, let pbInstance):
            eventModel = EventEditModel(copyFrom: pbEvent, instance: pbInstance)
            let timeZone: TimeZone
            if !pbInstance.startTimezone.isEmpty,
                let tz = TimeZone(identifier: pbInstance.startTimezone) {
                timeZone = tz
            } else {
                if eventModel.isAllDay {
                    // 全天日程的时区默认为 UTC/GMT
                    timeZone = TimeZone(identifier: "GMT") ?? TimeZone(secondsFromGMT: 0) ?? .current
                } else {
                    timeZone = .current
                }
            }
            eventModel.timeZone = timeZone

        }
        eventModel.span = span
        return eventModel
    }

    func makeEventModel() -> EventEditModelManager<EventEditModel> {
        let rxModel = BehaviorRelay<EventEditModel>(value: EventEditModel())
        let event_Model = EventEditModelManager<EventEditModel>(userResolver: self.userResolver,
                                                                identifier: EventEditModelType.event.rawValue,
                                                                rxModel: rxModel)
        event_Model.relyModel = [EventEditModelType.notes.rawValue, EventEditModelType.calendar.rawValue]
        event_Model.initMethod = { [weak self, weak event_Model] observer in
            guard let self = self, let event_Model = event_Model else {
                assertionFailureLog()
                return
            }
            var eventModel = self.makeEventModel(with: self.input)
            if let calendar = self.calendarModel?.rxModel?.value.current {
                eventModel.calendar = calendar
                if self.input.isFromCreating {
                    eventModel.makeCreatorOrganizer(for: calendar, primaryCalendarID: self.calendarManager?.primaryCalendarID)
                    if [.google, .exchange].contains(calendar.source) {
                        eventModel.videoMeeting.videoMeetingType = .noVideoMeeting
                    }
                }
            }
            if let notes = self.notesModel?.rxModel?.value {
                eventModel.notes = notes
            }
            event_Model.rxModel?.accept(eventModel)
            observer.onCompleted()
        }
        event_Model.initLater = { [weak self, weak event_Model] in
            // init_later
            guard let self = self,
                  let event_Model = event_Model,
                  let rxEvent = event_Model.rxModel else { return }

            rxEvent.delaySubscription(.seconds(1), scheduler: MainScheduler.instance)
                .skip(1).map { _ in true }
                .distinctUntilChanged()
                .bind(to: self.rxEventHasChanged)
                .disposed(by: self.disposeBag)

            // 用于会议室条件审批判断eventModel时间和rrule变化相关的场景
            rxEvent
                .map { [weak self] eventModel in
                    guard let self = self,
                          let originalEventModel = self.eventModelBeforeEditing else {
                              return false
                          }
                    let event = eventModel.getPBModel()
                    let originalEvent = originalEventModel.getPBModel()

                    let rruleChanged = self.checkChangedForRrule(with: event, and: originalEvent)

                    let dateChanged = self.checkChangedForDate(with: event, and: originalEvent)

                    let meetingRoomChanged = self.checkChangedForMeetingRooms(with: event, and: originalEvent)

                    return rruleChanged || dateChanged || meetingRoomChanged
                }
                .distinctUntilChanged()
                .bind(to: self.rxEventDateOrRruleChanged)
                .disposed(by: self.disposeBag)

            self.meetingRoomModel?.rxModel?
                .bind { [weak rxEvent] meetingRooms in
                    guard let rxEvent = rxEvent else { return }
                    var eventModel = rxEvent.value
                    eventModel.meetingRooms = meetingRooms
                    rxEvent.accept(eventModel)
                }.disposed(by: self.disposeBag)

            self.attachmentModel?.rxModel?
                .bind { [weak rxEvent] attachments in
                    guard let rxEvent = rxEvent else { return }
                    var eventModel = rxEvent.value
                    eventModel.attachments = attachments
                    rxEvent.accept(eventModel)
                }.disposed(by: self.disposeBag)

            self.notesModel?.rxModel?
                .bind { [weak rxEvent] notes in
                    guard let rxEvent = rxEvent else { return }
                    var eventModel = rxEvent.value
                    eventModel.notes = notes
                    rxEvent.accept(eventModel)
                }.disposed(by: self.disposeBag)

            self.attendeeModel?.rxModel?
                .bind { [weak rxEvent] attendees  in
                    guard let rxEvent = rxEvent else { return }
                    var eventModel = rxEvent.value
                    eventModel.attendees = attendees
                    rxEvent.accept(eventModel)
                }.disposed(by: self.disposeBag)

            self.webinarAttendeeModel?.rxModel?
                .bind { [weak rxEvent] webinarAttendees in
                    guard let rxEvent = rxEvent else { return }
                    var eventModel = rxEvent.value
                    eventModel.speakers = webinarAttendees.speaker
                    eventModel.audiences = webinarAttendees.audience
                    rxEvent.accept(eventModel)
                }.disposed(by: self.disposeBag)

            self.calendarModel?.rxModel?.subscribe(onNext: { [weak self, weak rxEvent] (prevCalendar, calendar) in
                guard let self = self,
                      let prevCalendar = prevCalendar,
                      let calendar = calendar,
                      let rxEvent = rxEvent else { return }
                let prevCalendarSource = prevCalendar.source
                let nextCalendarSource = calendar.source
                var eventModel = rxEvent.value

                let clearColor = {
                    eventModel.customizedColor = nil
                }
                let clearVideoMeetingType = {
                    guard self.input.isFromCreating else { return }
                    eventModel.videoMeeting.videoMeetingType = .noVideoMeeting
                }
                let adjustReminder = {
                    eventModel.reminders = Array(eventModel.reminders.prefix(1))
                }
                let clearRrule = {
                    if let daysOfTheMonth = eventModel.rrule?.daysOfTheMonth,
                        daysOfTheMonth.count > 1 {
                        eventModel.rrule = nil
                    }
                }

                let clearAttachments = {
                    let attachments = eventModel.attachments.map { origin in
                        var attachment = origin
                        attachment.isDeleted = true
                        return attachment
                    }
                    self.attachmentModel?.rxDisplayingAttachmentsInfo.accept((attachments, true))
                    eventModel.attachments = attachments
                }

                switch (prevCalendarSource, nextCalendarSource) {
                case (.lark, .google), (.exchange, .google):
                    clearVideoMeetingType()
                    clearColor()
                    clearAttachments()
                case (.lark, .exchange), (.google, .exchange):
                    clearVideoMeetingType()
                    adjustReminder()
                    clearRrule()
                    clearColor()
                    clearAttachments()
                default:
                    break
                }

                eventModel.calendar = calendar
                eventModel.makeCreatorOrganizer(for: calendar, primaryCalendarID: self.calendarManager?.primaryCalendarID)
                rxEvent.accept(eventModel)
            }).disposed(by: self.disposeBag)
        }
        return event_Model
    }

}
