//
//  InlineAI+Models.swift
//  Calendar
//
//  Created by pluto on 2023/9/26.
//

import Foundation
import LarkAIInfra
import ServerPB

struct CalendarBasicPromptParams {
    var quickActionCommand: String?
    var aiTaskId: String?
    var summary: String?
    var startTime: String?
    var endTime: String?
    var startTimeZone: String?
    var recRule: String?
    var resourceIDs: String?
    var participantIDs: String?
    var timeLength: String?
    var originalTime: String?
    var key: String?
    var meetingNotesUrl: String?
    
    init (quickActionCommand: String? = nil,
          aiTaskId: String? = nil,
          summary: String? = nil,
          startTime: String? = nil,
          endTime: String? = nil,
          startTimeZone: String? = nil,
          recRule: String? = nil,
          resourceIDs: String? = nil,
          participantIDs: String? = nil,
          timeLength: String? = nil,
          originalTime: String? = nil,
          key: String? = nil,
          meetingNotesUrl: String? = nil) {
        self.quickActionCommand = quickActionCommand
        self.aiTaskId = aiTaskId
        self.summary = summary
        self.startTime = startTime
        self.endTime = endTime
        self.startTimeZone = startTimeZone
        self.recRule = recRule
        self.resourceIDs = resourceIDs
        self.participantIDs = participantIDs
        self.timeLength = timeLength
        self.originalTime = originalTime
        self.key = key
        self.meetingNotesUrl = meetingNotesUrl
    }
}

extension LarkAIInfra.InlineAIPanelModel.Prompt {
    var groupType: QuickActionGroupType {
        guard let type = QuickActionGroupType(rawValue: extras ?? "") else {
            return .basic
        }
        return type
    }
    
    
    
    var promptType: EventEditCopilotQuickActionType {
        guard let type = EventEditCopilotQuickActionType(rawValue: originText ?? "") else {
            return .unknown
        }
        return type
    }
}

extension LarkAIInfra.InlineAIPanelModel.Operate {
    var opType: OperateType {
        guard let optype = OperateType(rawValue: type ?? "") else {
            return .unknown
        }
        return optype
    }
}

enum CalendarPromptActionType: String {
    case userPrompt = "user_prompt"
    case quickAction = "quick_action"
}

enum MaskType: String {
    case aroundPanel = "aroundPanel"
    case fullScreen = "fullScreen"
}

enum QuickActionGroupType: String {
    case template = "template"
    case basic = "basic"
    case adjust = "adjust"
}

enum OperateBtnType: String {
    case `default` = "default"
    case primary = "primary"
}

enum OperateType: String {
    case confirm = "confirm_ai_content"
    case adjust = "adjust_ai_content"
    case retry = "try_again_ai_content"
    case cancel = "cancel_ai_content"
    case debuginfo = "debuginfo"
    case unknown = "unknown"
}

enum FeedBackPosition: String {
    case tips = "tips"
    case history = "history"
}

enum EventEditCopilotQuickActionType: String {
    // 基础指令
    case completeEvent = "complete_event"
    case recommendTime = "recommend_time"
    case createMeetingNotes = "create_meeting_notes"
    case bookRooms = "book_rooms"
    // 模版指令
    case scheduleFocusTime = "schedule_focus_time"
    case projectDailyMeeting = "project_daily_meeting"
    case scheduleOneOnOneMeeting = "schedule_one_on_one_meeting"
    // 调整指令
    case rewriteMeetingNotes = "rewrite_meeting_notes"
    case changeRooms = "change_rooms"
    case changeTime = "change_time"
    
    case unknown = ""
}

/// success：明确成功
/// processing： ack、处理中
/// time_out： 链路某一处超时
/// failed：明确失败
/// tns_block：tns 管控
/// off_line： rust层的处理，网络中断
enum AiTaskStatus: String {
    case success = "success"
    case failed = "failed"
    case processing = "processing"
    case timeOut = "time_out"
    case tnsBlock = "tns_block"
    case offline = "off_line"
    case unknown = "unknown"
    case initial = "initial"
    case finish = "finish"
}

struct CalendarAITask {
    var taskID: String
    var promptID: String?
    var params: [String: String]
    var userPrompt: String?
    var fullInput: String
}

struct InlineAIEventFullInfo {
    var model: EventEditModel?
    var attendee: [EventEditAttendee]?
    var simpleAttendees: [Rust.IndividualSimpleAttendee]?
    var meetinRooms: [CalendarMeetingRoom]?
    var meetingNotesModel: MeetingNotesModel?
    var dateChanged: Bool
    var rruleChanged: Bool
    var feedback: FeedBackStatus
    init(model: EventEditModel?,
                attendee: [EventEditAttendee]?,
                simpleAttendees: [Rust.IndividualSimpleAttendee]?,
                meetinRooms: [CalendarMeetingRoom]?,
                meetingNotesModel: MeetingNotesModel?,
                dateChanged: Bool = false,
                rruleChanged: Bool = false,
                feedback: FeedBackStatus = .unknown) {
        self.model = model
        self.attendee = attendee
        self.simpleAttendees = simpleAttendees
        self.meetinRooms = meetinRooms
        self.meetingNotesModel = meetingNotesModel
        self.dateChanged = dateChanged
        self.rruleChanged = rruleChanged
        self.feedback = feedback
    }
}

struct InlineAIEventHistory {
    var summary: String
    var startTime: String
}

enum AIGenerateEventInfoType {
    case summary
    case attendee
    case time
    case rrule
    case meetingRoom
    case meetingNotes
}

enum AIGenerateResourceType {
    case unknown
    case normalResource
    /// ble 低功耗蓝牙，此处代表蓝牙类型会议室
    case bleResource
}

struct AIGenerateMeetingRoom {
    var resourceID: String
    var resourceType: AIGenerateResourceType
    init(resourceID: String, resourceType: AIGenerateResourceType = .normalResource) {
        self.resourceID = resourceID
        self.resourceType = resourceType
    }
}
struct AIGenerateEventInfoNeedHightLight {
    
    var summary: Bool
    var time: (startTime: Bool, endTime: Bool)
    var rrule: (rrule: Bool, endTime: Bool)
    var attendee: [String]
    var meetingRoom: [AIGenerateMeetingRoom]
    var meetingNotes: Bool
    init(summary: Bool = false,
         time: (startTime: Bool, endTime: Bool) = (false, false),
         rrule: (rrule: Bool, endTime: Bool) = (false, false),
         attendee: [String] = [],
         meetingRoom: [AIGenerateMeetingRoom] = [],
         meetingNotes: Bool = false) {
        self.summary = summary
        self.time = time
        self.rrule = rrule
        self.attendee = attendee
        self.meetingRoom = meetingRoom
        self.meetingNotes = meetingNotes
    }
}

struct InlineAIEventInfo {
    var eventInfo: Server.MyAICalendarEventInfo?
    var stage: Server.CalendarMyAIInlineStage
    var needHightLight: AIGenerateEventInfoNeedHightLight
    var type: AIGenerateEventInfoType
    var inAdjustMode: Bool
    var meetingRoomModels: [CalendarMeetingRoom]
    var meetingNotesModel: MeetingNotesModel?
    var attendeeCompleteCallBack: (()->Void)?
    init(eventInfo: Server.MyAICalendarEventInfo?,
         stage: Server.CalendarMyAIInlineStage,
         needHightLight: AIGenerateEventInfoNeedHightLight,
         type: AIGenerateEventInfoType,
         inAdjustMode: Bool,
         meetingRoomModels: [CalendarMeetingRoom] = [],
         meetingNotesModel: MeetingNotesModel? = nil,
         attendeeCompleteCallBack: (()->Void)? = nil) {
        self.eventInfo = eventInfo
        self.stage = stage
        self.needHightLight = needHightLight
        self.type = type
        self.inAdjustMode = inAdjustMode
        self.meetingRoomModels = meetingRoomModels
        self.meetingNotesModel = meetingNotesModel
        self.attendeeCompleteCallBack = attendeeCompleteCallBack
    }
}

struct InlineNavItemStatus {
    var status: InlineAIViewModel.Status
    var leftNavEnable: Bool?
    var rightNavEnable: Bool?
    init(status: InlineAIViewModel.Status, leftNavEnable: Bool? = nil, rightNavEnable: Bool? = nil) {
        self.status = status
        self.leftNavEnable = leftNavEnable
        self.rightNavEnable = rightNavEnable
    }
}


struct AIFreeParamsParticipant: Codable {
    var user_id: String
    var name: String
}

struct AIFreeParamsRoom: Codable {
    var room_id: String
    var name: String
}

enum FeedBackStatus {
    case unknown
    case like
    case unlike
}
