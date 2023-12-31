//
//  ScheduleCardBtnModel.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/18.
//
import RustPB

enum ScheduleCardBtnType {
    case vcBtn(ScheduleCardButtonModel)
    case otherBtn(OtherVideoMeetingBtnManager)
}

public struct ScheduleCardButtonModel {
    public let uniqueId: String
    public let key: String //calendarEvent.key
    public let originalTime: Int64 //calendarEvent.originalTime
    public let startTime: Int64 // calendarInstance.startTime
    public let endTime: Int64 // calendarInstance.endTime
    public let displayTitle: String // calendarEvent.displayTitle
    public let isFromPeople: Bool // calendarEvent.source == .people
    public let isWebinar: Bool
    public let isWebinarOrganizer: Bool
    public let isWebinarSpeaker: Bool
    public let isWebinarAudience: Bool
    public let videoMeetingType: Calendar_V1_VideoMeeting.VideoMeetingType
    public let url: String // Rust.VideoMeeting.url
    public let isExpired: Bool // Rust.VideoMeeting.isExpired
    public let isTop: Bool
    public let feedTab: String
}

class OtherMeetingBtnModel {
    let videoMeeting: Calendar_V1_VideoMeeting
    let location: String
    let description: String
    let source: Rust.CalendarEventSource
    init(videoMeeting: Calendar_V1_VideoMeeting,
         location: String,
         description: String,
         source: Rust.CalendarEventSource) {
        self.videoMeeting = videoMeeting
        self.location = location
        self.description = description
        self.source = source
    }
}
