//
//  EventEditViewModel+Inline.swift
//  Calendar
//
//  Created by pluto on 2023/11/6.
//

import Foundation
import EventKit

extension EventEditViewModel {
    
    /// 更新编辑页EventInfo. For Full Block
    func updateFullEventInfoFromAI(data: InlineAIEventFullInfo) {
        if let sourceModel = data.model {
            eventModel?.rxModel?.accept(sourceModel)
        }
        
        if let attendee = data.attendee, let simpleAttendees = data.simpleAttendees {
            attendeeModel?.resetAttedees(attendees: attendee, simpleAttendees: simpleAttendees)
        }
        
        if let meetingRooms = data.meetinRooms {
            meetingRoomModel?.resetMeetingRooms(meetingRooms)
        }
        
        meetingNotesModel?.resetMeetingNote(model: data.meetingNotesModel)
    }
    
    /// 更新编辑页EventInfo. 每次只更新一个Block， For Single Block
    func updateEventInfoFromAI(data: InlineAIEventInfo) {
        guard var model = eventModel?.rxModel?.value else { return }
        switch data.type {
        case .summary:
            model.summary = data.eventInfo?.summary
            model.aiStyleInfo.summary = data.needHightLight.summary
            
            eventModel?.rxModel?.accept(model)
        case .attendee:
            var participants: [EventAttendeeSeed] = []
            data.eventInfo?.participantIds.map {
                participants.append(.user(chatterId: $0.description))
            }
            
            let ids = data.eventInfo?.participantIds.map { $0.description } ?? []
            model.aiStyleInfo.attendee += ids
            eventModel?.rxModel?.accept(model)
            
            attendeeModel?.addAttendees(withSeeds: participants, onCompleted: data.attendeeCompleteCallBack)
        case .time:
            if data.needHightLight.time.startTime {
                model.startDate = Date(timeIntervalSince1970: TimeInterval(data.eventInfo?.startTime ?? 0))
            }
            
            if data.needHightLight.time.endTime {
                model.endDate = Date(timeIntervalSince1970: TimeInterval(data.eventInfo?.endTime ?? 0))
            }
            model.aiStyleInfo.time = data.needHightLight.time
            
            eventModel?.rxModel?.accept(model)
        case .rrule:
            model.rrule = EKRecurrenceRule.recurrenceRuleFromString(data.eventInfo?.recRule ?? "")
            model.aiStyleInfo.rrule = data.needHightLight.rrule
            
            eventModel?.rxModel?.accept(model)
            
        case .meetingRoom:
            guard let resourceIds = data.eventInfo?.resourceIds else { return }
            model.aiStyleInfo.meetingRoom = data.needHightLight.meetingRoom
            eventModel?.rxModel?.accept(model)
            if data.inAdjustMode {
                meetingRoomModel?.resetMeetingRooms(data.meetingRoomModels)
            } else {
                meetingRoomModel?.addMeetingRooms(data.meetingRoomModels, isAIAppend: true)
            }
        case .meetingNotes:
            model.aiStyleInfo.meetingNotes = true
            eventModel?.rxModel?.accept(model)
            
            meetingNotesModel?.resetMeetingNote(model: data.meetingNotesModel)

        default: break
        }
    }
    
    /// 获取当前完整日程信息
    func getCurrentEventInfo() -> InlineAIEventFullInfo {
        let model = eventModel?.rxModel?.value
        let attendee = attendeeModel?.rxAttendees.value
        let simpleAttendees = attendeeModel?.rxNewSimpleAttendees.value
        let meetingRooms = meetingRoomModel?.rxMeetingRooms.value
        let meetingNotes = meetingNotesModel?.currentNotes
        
        if let event = model?.getPBModel(), let originalEvent = eventModelBeforeEditing?.getPBModel() {
            let dateChanged = checkChangedForDate(with: event, and: originalEvent)
            let rruleChanged = checkChangedForRrule(with: event, and: originalEvent)
            return InlineAIEventFullInfo(model: model,
                                         attendee: attendee,
                                         simpleAttendees: simpleAttendees,
                                         meetinRooms: meetingRooms,
                                         meetingNotesModel: meetingNotes,
                                         dateChanged: dateChanged,
                                         rruleChanged: rruleChanged)
        }
        return InlineAIEventFullInfo(model: model,
                                     attendee: attendee,
                                     simpleAttendees: simpleAttendees,
                                     meetinRooms: meetingRooms,
                                     meetingNotesModel: meetingNotes)
    }
}
