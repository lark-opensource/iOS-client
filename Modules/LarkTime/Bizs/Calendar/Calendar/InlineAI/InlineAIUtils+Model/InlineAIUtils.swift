//
//  InlineAIUtils.swift
//  Calendar
//
//  Created by pluto on 2023/10/26.
//

import Foundation
import LarkAIInfra

struct InlineAIUtils {
    
    static func transferToISOFormatDate(date: Date, timezone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = timezone
        return formatter.string(from: date)
    }
    
    /// 根据指令类型获取对应Icon
    static func getPomptIcon(type: EventEditCopilotQuickActionType) -> PromptIcon {
        switch type {
        case .scheduleFocusTime, .scheduleOneOnOneMeeting, .projectDailyMeeting:
            return .calendarOutlined
        case .completeEvent:
            return .calendarEditOutlined
        case .recommendTime:
            return .timeOutlined
        case .bookRooms:
            return .roomOutlined
        case .createMeetingNotes:
            return .fileLinkDocxOutlined
        default:
            return .calendarOutlined
        }
    }
    
    /// 参数组装
    static func getPromptParams(data: CalendarBasicPromptParams) -> [String: String] {
        var params: [String: String] = [:]
        
        if let quickActionCommand = data.quickActionCommand {
            params["quick_action_command"] = quickActionCommand
        }
        
        if let aiTaskId = data.aiTaskId {
            params["ai_task_id"] = aiTaskId
        }
        
        if let startTimeZone = data.startTimeZone {
            params["start_timezone"] = startTimeZone
        }
        
        if let summary = data.summary {
            params["summary"] = summary
        }
        
        if let startTime = data.startTime {
            params["start_time"] = startTime
        }
        
        if let endTime = data.endTime {
            params["end_time"] = endTime
        }
        
        if let recRule = data.recRule {
            params["rec_rule"] = recRule
        }
        
        if let resourceIDs = data.resourceIDs {
            params["resource_ids"] = resourceIDs
        }
            
        if let participantIDs = data.participantIDs {
            params["participant_ids"] = participantIDs
        }
        
        if let timeLength = data.timeLength {
            params["time_length"] = timeLength
        }
        
        if let originalTime = data.originalTime {
            params["origin_time"] = originalTime
        }
        
        if let eventUid = data.key {
            params["evnet_uid"] = eventUid
        }
        
        if let meetingNotesUrl = data.meetingNotesUrl {
            params["meeting_notes_url"] = meetingNotesUrl
        }
        
        return params
    }
}
