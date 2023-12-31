//
//  InlineAIViewModel+Params.swift
//  Calendar
//
//  Created by pluto on 2023/10/19.
//

import Foundation
import CalendarFoundation
import LarkAIInfra

// MARK: - 指令执行参数组装
extension InlineAIViewModel {

    func getTriggerParams() -> [String: String] {
        guard let eventModel = currentEventInfo?.model else { return [:] }
        switch editType {
        case .edit:
            let model = getBasicParamsModel(eventModel: eventModel, true)
            return InlineAIUtils.getPromptParams(data: model)
            
        case .new:
            let dateChanged = originalEventInfo?.dateChanged ?? false
            let rruleChanged = originalEventInfo?.rruleChanged ?? false
            var model = getBasicParamsModel(eventModel: eventModel, true)
            
            model.startTime = dateChanged ? eventModel.startDate.description : nil
            model.endTime = dateChanged ? eventModel.endDate.description : nil
            model.recRule = rruleChanged ? eventModel.rrule?.description : nil
            return InlineAIUtils.getPromptParams(data: model)
        }
    }
    
    func getFreePomptParams(freeParams: [InlineAIPanelModel.ParamContentComponent]) -> [String: String] {
        guard let eventModel = currentEventInfo?.model else { return [:] }

        let userIDs: [String] = getPrasedUserID(params: freeParams)
        var participantIDs: [String] = getAttendeeParams(attendees: eventModel.attendees)

        if participantIDs.isEmpty {
            participantIDs.append(userResolver.userID)
            if let id = eventModel.calendar?.userChatterId {
                participantIDs.append(id)
            }
        }

        let totalParticipantIDs: [String] = userIDs + participantIDs.unique
        let idsList = totalParticipantIDs.map {
            return AIFreeParamsParticipant(user_id: $0, name: "")
        }
        let participantIDsStr = encodeParamsToJson(participants: idsList)
        uniqueTaskID = UUID().uuidString
        switch editType {
        case .edit:
            var model = getBasicParamsModel(eventModel: eventModel)
            model.startTime = InlineAIUtils.transferToISOFormatDate(date: eventModel.startDate, timezone: eventModel.timeZone)
            model.endTime = InlineAIUtils.transferToISOFormatDate(date: eventModel.endDate, timezone: eventModel.timeZone)
            model.participantIDs = participantIDsStr
            model.originalTime = eventModel.getPBModel().originalTime.description
            model.key = eventModel.getPBModel().key
            model.aiTaskId = uniqueTaskID
            model.recRule = eventModel.rrule?.iCalendarString().description
            model.meetingNotesUrl = nil
            return InlineAIUtils.getPromptParams(data: model)
        case .new:
            let dateChanged = originalEventInfo?.dateChanged ?? false
            let rruleChanged = originalEventInfo?.rruleChanged ?? false
            var model = getBasicParamsModel(eventModel: eventModel)
            model.aiTaskId = uniqueTaskID
            model.participantIDs = participantIDsStr
            model.startTime = dateChanged ? InlineAIUtils.transferToISOFormatDate(date: eventModel.startDate, timezone: eventModel.timeZone) : nil
            model.endTime = dateChanged ? InlineAIUtils.transferToISOFormatDate(date: eventModel.endDate, timezone: eventModel.timeZone) : nil
            model.recRule = rruleChanged ? eventModel.rrule?.iCalendarString().description : nil
            model.meetingNotesUrl = nil
            return InlineAIUtils.getPromptParams(data: model)
        }
    }
    
    func getTemplatePomptParams(data: InlineAIPanelModel.QuickAction) -> [String: String] {
        logger.info("template params: \(data.paramDetails)")
        guard let eventModel = currentEventInfo?.model else { return [:] }

        var model = CalendarBasicPromptParams()
        model.quickActionCommand = getQuickCommandMark(data: data)
        uniqueTaskID = UUID().uuidString
        model.aiTaskId = uniqueTaskID
        model.startTimeZone = eventModel.timeZone.identifier
        model.meetingNotesUrl = currentEventInfo?.meetingNotesModel?.url
        var params = InlineAIUtils.getPromptParams(data: model)
        var userIDs: [String] = []

        for item in data.paramDetails {
            if item.key == "participant_ids" {
                for componentItem in (item.contentComponents ?? []) {
                    switch componentItem {
                    case .plainText(_):
                        params[item.key] = item.content
                    case .mention(let data):
                        switch data {
                        case .user(_, let userID):
                            userIDs.append(userID)
                        default:break
                        }
                    }
                }

                if !userIDs.isEmpty {
                    if let ownCaledarID = eventModel.calendar?.userChatterId, eventModel.attendees.isEmpty {
                        userIDs.append(ownCaledarID)
                    }
                    params[item.key] = userIDs.joined(separator: ";")
                    userIDs = []
                }
            } else {
                params[item.key] = item.content
            }
        }
        return params
    }
    
    func getAdjustPomptParams(prompt: LarkAIInfra.InlineAIPanelModel.Prompt) -> [String: String]  {
        guard let eventModel = currentEventInfo?.model else { return [:] }

        switch editType {
        case .edit:
            var model = getBasicParamsModel(eventModel: eventModel)
            model.quickActionCommand = prompt.type
            uniqueTaskID = UUID().uuidString
            model.aiTaskId = uniqueTaskID
            model.originalTime = eventModel.getPBModel().originalTime.description
            model.startTime = Int64(eventModel.startDate.timeIntervalSince1970).description
            model.endTime = Int64(eventModel.endDate.timeIntervalSince1970).description
            model.key = eventModel.getPBModel().key
            model.recRule = eventModel.rrule?.iCalendarString().description
            return InlineAIUtils.getPromptParams(data: model)
        case .new:
            var model = getBasicParamsModel(eventModel: eventModel)
            model.quickActionCommand = prompt.type
            uniqueTaskID = UUID().uuidString
            model.aiTaskId = uniqueTaskID
            model.startTime = Int64(eventModel.startDate.timeIntervalSince1970).description
            model.endTime = Int64(eventModel.endDate.timeIntervalSince1970).description
            model.recRule = eventModel.rrule?.iCalendarString().description
            return InlineAIUtils.getPromptParams(data: model)
        }
    }
    
    func getQuickPomptParams(prompt: LarkAIInfra.InlineAIPanelModel.Prompt) -> [String: String]  {
        guard let eventModel = currentEventInfo?.model else { return [:] }
        switch editType {
        case .edit:
            var model = getBasicParamsModel(eventModel: eventModel)
            model.quickActionCommand = prompt.type
            uniqueTaskID = UUID().uuidString
            model.aiTaskId = uniqueTaskID
            model.originalTime = eventModel.getPBModel().originalTime.description
            model.key = eventModel.getPBModel().key
            model.startTime = Int64(eventModel.startDate.timeIntervalSince1970).description
            model.endTime = Int64(eventModel.endDate.timeIntervalSince1970).description
            return InlineAIUtils.getPromptParams(data: model)
        case .new:
            let dateChanged = originalEventInfo?.dateChanged ?? false
            let rruleChanged = originalEventInfo?.rruleChanged ?? false
            var model = getBasicParamsModel(eventModel: eventModel)
            model.quickActionCommand = prompt.type
            uniqueTaskID = UUID().uuidString
            model.aiTaskId = uniqueTaskID
            model.startTime = dateChanged ? Int64(eventModel.startDate.timeIntervalSince1970).description : nil
            model.endTime = dateChanged ? Int64(eventModel.endDate.timeIntervalSince1970).description : nil
            model.recRule = rruleChanged ? eventModel.rrule?.iCalendarString().description : nil
            return InlineAIUtils.getPromptParams(data: model)
        }
    }
    
    private func getBasicParamsModel(eventModel :EventEditModel, _ isTrigger: Bool = false) -> CalendarBasicPromptParams {
        var participantIDs: [String] = getAttendeeParams(attendees: eventModel.attendees)
        let triggerParticipant: String? = !participantIDs.isEmpty ? participantIDs.count.description : nil
        if participantIDs.isEmpty, let id = eventModel.calendar?.userChatterId {
            participantIDs.append(id)
        }
        let meetingRoomIDs: [String] = eventModel.aiStyleInfo.meetingRoom.isEmpty ? eventModel.meetingRooms.map {$0.uniqueId} : eventModel.aiStyleInfo.meetingRoom.map { $0.resourceID }
        let model = CalendarBasicPromptParams(summary: eventModel.summary,
                                              startTime: eventModel.startDate.description,
                                              endTime: eventModel.endDate.description,
                                              startTimeZone: isTrigger ? nil : eventModel.timeZone.identifier,
                                              recRule: eventModel.rrule?.iCalendarString().description,
                                              resourceIDs: meetingRoomIDs.isEmpty ? nil : meetingRoomIDs.joined(separator: ";"),
                                              participantIDs: isTrigger ? triggerParticipant : participantIDs.joined(separator: ";"),
                                              meetingNotesUrl: originalEventInfo?.meetingNotesModel?.url)
        return model
    }
    
    private func getQuickCommandMark(data: InlineAIPanelModel.QuickAction) -> String? {
        for item in quickActionList {
            if item.name == data.displayName {
                guard let extraMap = item.extraMap["Comment"]?.data(using: .utf8) else {
                    self.logger.error("error transfer quickActionList extraMap")
                    return nil
                }
                do {
                    let dictValue = try JSONSerialization.jsonObject(with: extraMap, options: []) as? [String: String]
                    let quickCommandMark: String = dictValue?["quick_action_command"] ?? ""
                    return quickCommandMark
                } catch{
                    return nil
                }
                break
            }
        }
        return nil
    }
    
    private func getPrasedUserID(params: [InlineAIPanelModel.ParamContentComponent]) -> [String] {
        var userIDs: [String] = []
        for item in params {
            switch item {
            case .mention(let data):
                switch data {
                case .user(_, let userID):
                    userIDs.append(userID)
                default: break
                }
            default: break
            }
        }
        return userIDs
    }
    
    /// 打散参与人
    private func getAttendeeParams(attendees: [EventEditAttendee]) -> [String] {
        var participantIDs: [String] = []
        for attendee in attendees {
            switch attendee {
            case .user(let data):
                participantIDs.append(data.chatterId)
            case .group(let data):
                for item in data.memberSeeds {
                    participantIDs.append(item.user.chatterID)
                    if participantIDs.count > 10 { return participantIDs }
                }
            default: break
            }
        }
        return participantIDs
    }
    
    func encodeParamsToJson(participants: [AIFreeParamsParticipant]? = nil, rooms: [AIFreeParamsRoom]? = nil) -> String {
        do {
            if let participants = participants {
                let data = try JSONEncoder().encode(participants)
                let participantIDsStr = String(data: data, encoding: String.Encoding.utf8) ?? ""
                return participantIDsStr
            }
            
            if let rooms = rooms {
                let data = try JSONEncoder().encode(rooms)
                let roomsStr = String(data: data, encoding: String.Encoding.utf8) ?? ""
                return roomsStr
            }
        } catch {
            return ""
        }
        return ""
    }
    
    func getTaskTypeParamsForTracker(type: EventEditCopilotQuickActionType) -> String {
        switch type {
        case .scheduleFocusTime:
            return "schedule_focus_time"
        case .scheduleOneOnOneMeeting:
            return "schedule_one_one_meeting"
        case .completeEvent:
            return "complete_event"
        case .recommendTime:
            return "recommend_time"
        case .bookRooms:
            return "book_room"
        case .createMeetingNotes:
            return "create_meeting_notes"
        default: return ""
        }
    }
}
