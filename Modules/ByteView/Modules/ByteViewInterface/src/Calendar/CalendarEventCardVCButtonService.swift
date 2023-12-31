//
//  CalendarEventCardVCButtonService.swift
//  ByteViewInterface
//
//  Created by lutingting on 2023/8/2.
//

import Foundation

public protocol CalendarEventCardButtonService {
    /// 创建 VCButton
    func createEventCardButton(_ info: EventCardButtonInfo) -> UIButton

    /// 移除 VCButton
    func remove(uniqueId: String)

    func removeAll()

    /// 更新Button状态
    func updateStatus(_ info: EventCardButtonInfo)
}

public struct EventCardButtonInfo {
    public enum VideoMeetingType: Equatable {
        case unknownVideoMeetingType
        /// VC会议链接
        case vchat // = 1
        case other // = 2
        /// Lark直播主播链接
        case larkLiveHost // = 3
        case noVideoMeeting // = 4
        /// google vc
        case googleVideoConference // = 5
        /// zoom vc
        case zoomVideoMeeting // = 6
    }

    public let uniqueId: String // 等同calendarEvent.calendarID
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
    public let videoMeetingType: VideoMeetingType
    public let url: String // Rust.VideoMeeting.url
    public let isExpired: Bool // Rust.VideoMeeting.isExpired
    public let isTop: Bool // 事件列表展开时，此时事件在主feed中是否置顶
    public let feedTab: String // 事件列表展开时所属的分组

    public init(uniqueId: String, key: String, originalTime: Int64, startTime: Int64, endTime: Int64, displayTitle: String, isFromPeople: Bool, isWebinar: Bool, isWebinarOrganizer: Bool, isWebinarSpeaker: Bool, isWebinarAudience: Bool, videoMeetingType: VideoMeetingType, url: String, isExpired: Bool, isTop: Bool, feedTab: String) {
        self.uniqueId = uniqueId
        self.key = key
        self.originalTime = originalTime
        self.startTime = startTime
        self.endTime = endTime
        self.displayTitle = displayTitle
        self.isFromPeople = isFromPeople
        self.isWebinar = isWebinar
        self.isWebinarOrganizer = isWebinarOrganizer
        self.isWebinarSpeaker = isWebinarSpeaker
        self.isWebinarAudience = isWebinarAudience
        self.videoMeetingType = videoMeetingType
        self.url = url
        self.isExpired = isExpired
        self.isTop = isTop
        self.feedTab = feedTab
    }
}
