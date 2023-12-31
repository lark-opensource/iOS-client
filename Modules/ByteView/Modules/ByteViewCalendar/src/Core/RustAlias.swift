//
//  RustAlias.swift
//  ByteViewMod
//
//  Created by tuwenbo on 2022/9/15.
//

import Foundation
import RustPB
import ServerPB

enum Rust {}
enum Server {}

extension Rust {
    // 日程关联的视频会议
    typealias VideoMeeting = RustPB.Calendar_V1_VideoMeeting
    typealias VideoMeetingStatus = RustPB.Calendar_V1_VideoMeeting.Status
    typealias VideoMeetingIconType = RustPB.Calendar_V1_EventVideoMeetingConfig.OtherVideoMeetingConfigs.IconType
    typealias CalendarEvent = RustPB.Calendar_V1_CalendarEvent
    typealias CalendarInstance = RustPB.Calendar_V1_CalendarEventInstance

    // 视频会议信息 change 的通知
    typealias VideoMeetingChangeNotiPayload = RustPB.Calendar_V1_PushCalendarEventVideoMeetingChange
    typealias VideoMeetingNotiInfo = VideoMeetingChangeNotiPayload.EventVideoMeetingInfo
    typealias VideoChatStatusNotiPayload = RustPB.Videoconference_V1_GetAssociatedVideoChatStatusResponse
    typealias AssociatedLiveStatus = RustPB.Videoconference_V1_AssociatedLiveStatus

    typealias GetVideoMeetingByEventRequest = RustPB.Calendar_V1_GetVideoMeetingByEventRequest
    typealias GetVideoMeetingByEventResponse = RustPB.Calendar_V1_GetVideoMeetingByEventResponse
    typealias GetVideoMeetingsStatusRequest = RustPB.Calendar_V1_GetVideoMeetingsStatusRequest
    typealias GetVideoMeetingsStatusResponse = RustPB.Calendar_V1_GetVideoMeetingsStatusResponse
    typealias GetCanRenewExpiredVideoMeetingNumberRequest = RustPB.Calendar_V1_GetCanRenewExpiredVideoMeetingNumberRequest
    typealias GetCanRenewExpiredVideoMeetingNumberResponse = RustPB.Calendar_V1_GetCanRenewExpiredVideoMeetingNumberResponse

    typealias CalendarEventAttendee = RustPB.Calendar_V1_CalendarEventAttendee

    typealias GetJoinedDevicesInfoRequest = RustPB.Videoconference_V1_GetJoinedDevicesInfoRequest
    typealias GetJoinedDevicesInfoResponse = RustPB.Videoconference_V1_GetJoinedDevicesInfoResponse
    typealias JoinedDevice = RustPB.Videoconference_V1_JoinedDeviceInfo
}

extension Server {
    typealias CalendarVideoChatStatus = ServerPB.ServerPB_Videochat_CalendarVideoChatStatus
    typealias GetCalendarVchatStatusRequest = ServerPB.ServerPB_Videochat_GetCalendarVchatStatusRequest
    typealias GetCalendarVchatStatusResponse = ServerPB_Videochat_GetCalendarVchatStatusResponse
}
