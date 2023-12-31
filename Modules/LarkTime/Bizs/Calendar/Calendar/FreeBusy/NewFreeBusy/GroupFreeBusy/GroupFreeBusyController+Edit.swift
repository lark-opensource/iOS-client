//
//  GroupFreeBusyControllerGroupFreeBusyController+Edit.swift
//  Calendar
//
//  Created by pluto on 2023/9/6.
//

import Foundation
import EENavigator
import UIKit


extension GroupFreeBusyController: EventEditCoordinatorDelegate {

    func coordinator(
        _ coordinator: EventEditCoordinator,
        didSaveEvent pbEvent: Rust.Event,
        span: Span,
        extraData: EventEditExtraData?
    ) {
        let topMost = WindowTopMostFrom(vc: self)
        let handler = viewModel.createEventSucceedHandler
        dismiss(animated: false) {
            if let from = topMost.fromViewController {
                handler(pbEvent, from)
            }
        }
    }

    func initNewEventHandle() {
        groupFreeBusyView.addNewEvent = { [weak self] (_, _) in
            guard let `self` = self else { return }
            let model = self.viewModel.groupFreeBusyModel
            let attedees = model.attendees.map { attendee -> CalendarEventAttendeeEntity in
                return attendee
            }
            var timeConflict: CalendarTracer.CalFullEditEventParam.TimeConfilct = .noConflict
            if !model.workHourConflictCalendarIds.isEmpty {
                timeConflict = .workTime
            } else if model.workHourConflictCalendarIds.isEmpty {
                timeConflict = .eventConflict
            }
            let actionSource: CalendarTracer.CalFullEditEventParam.ActionSource = self.viewModel.chatType == "group" ? .findTimeGroup : .findTimeSingle
            CalendarTracer.shareInstance.calFullEditEvent(actionSource: actionSource,
                                                          editType: .new,
                                                          mtgroomCount: 0,
                                                          thirdPartyAttendeeCount: 0,
                                                          groupCount: 0,
                                                          userCount: 0,
                                                          timeConfilct: timeConflict)
            let restrictedUserids = self.viewModel.groupFreeBusyModel.usersRestrictedForNewEvent
            let filteredAttendees = attedees.filter { !restrictedUserids.contains($0.id) }

            self.createEvent(
                withStartDate: self.viewModel.groupFreeBusyModel.startTime,
                endDate: self.viewModel.groupFreeBusyModel.endTime,
                meetingRooms: self.viewModel.createEventBody?.meetingRoom ?? [],
                attendees: filteredAttendees
            )
        }
    }

    func createEvent(
        withStartDate startDate: Date,
        endDate: Date,
        meetingRooms: [(fromResource: Rust.MeetingRoom, buildingName: String, tenantId: String)],
        attendees: [CalendarEventAttendeeEntity]
    ) {
        ReciableTracer.shared.recStartEditEvent()
        let attendeeSeeds: [EventAttendeeSeed]
        if let inputAttendee = viewModel.createEventBody?.attendees.first,
           case .group(let chatId, let memberCount) = inputAttendee, memberCount == attendees.count {
            attendeeSeeds = [.group(chatId: chatId)]
        } else {
            attendeeSeeds = attendees.compactMap {
                guard let chatterId = $0.chatterId else { return nil }
                return .user(chatterId: chatterId)
            }
        }
        let editCoordinator = viewModel.getCreateEventCoordinator { contextPointer in
            contextPointer.pointee.startDate = startDate
            contextPointer.pointee.endDate = endDate
            contextPointer.pointee.attendeeSeeds = attendeeSeeds
            contextPointer.pointee.chatIdForSharing = self.viewModel.chatId
            contextPointer.pointee.meetingRooms = meetingRooms
        }
        editCoordinator.delegate = self
        let scheduleConflictNum = (self.viewModel.groupFreeBusyModel.freeBusyInfo?.busyAttendees.count ?? 0) +
        (self.viewModel.groupFreeBusyModel.freeBusyInfo?.maybeFreeAttendees.count ?? 0)
        let attendeeNum = attendees.count
        editCoordinator.actionSource = self.viewModel.chatType == "group" ? .chat(scheduleConflictNum: scheduleConflictNum, attendeeNum: attendeeNum) : .chatter
        editCoordinator.start(from: self)
        self.groupFreeBusyView.hideInterval()
        CalendarTracerV2.CalendarChat
            .traceClick {
                $0.chat_id = self.viewModel.chatId
                $0.click("full_create_event").target("cal_event_full_create_view")
            }
    }
}
