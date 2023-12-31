//
//  JoinMeetingByCalendarBody.swift
//  ByteViewInterface
//
//  Created by kiri on 2023/6/29.
//

import Foundation

/// 通过日程会议入会, /client/byteview/joinbycalendar
public struct JoinMeetingByCalendarBody: CodablePathBody {
    public static let path: String = "/client/byteview/joinbycalendar"

    public let uniqueId: String     // 日程唯一标识
    public let uid: String
    public let originalTime: Int64
    public let instanceStartTime: Int64
    public let instanceEndTime: Int64
    public var title: String?
    public let entrySource: VCMeetingEntry
    public let linkScene: Bool      // 是否通过链接入会
    public let isStartMeeting: Bool
    public let isWebinar: Bool

    public var calendarInstance: CalendarInstanceIdentifier {
        CalendarInstanceIdentifier(uniqueID: uniqueId, uid: uid, originalTime: originalTime, instanceStartTime: instanceStartTime, instanceEndTime: instanceEndTime)
    }

    public init(uniqueId: String, uid: String, originalTime: Int64, instanceStartTime: Int64, instanceEndTime: Int64, title: String?, entrySource: VCMeetingEntry, linkScene: Bool, isStartMeeting: Bool, isWebinar: Bool) {
        self.uniqueId = uniqueId
        self.uid = uid
        self.originalTime = originalTime
        self.instanceStartTime = instanceStartTime
        self.instanceEndTime = instanceEndTime
        self.title = title
        self.entrySource = entrySource
        self.linkScene = linkScene
        self.isStartMeeting = isStartMeeting
        self.isWebinar = isWebinar
    }
}

extension JoinMeetingByCalendarBody: CustomStringConvertible {
    public var description: String {
        "JoinMeetingByCalendarBody(uniqueId: \(uniqueId), uid: \(uid), entrySource: \(entrySource), linkScene: \(linkScene), isStartMeeting: \(isStartMeeting), isWebinar: \(isWebinar)"
    }
}

public struct CalendarInstanceIdentifier {
    public let uniqueID: String
    public let uid: String
    public let originalTime: Int64
    public let instanceStartTime: Int64
    public let instanceEndTime: Int64

    public init(uniqueID: String, uid: String, originalTime: Int64, instanceStartTime: Int64, instanceEndTime: Int64) {
        self.uniqueID = uniqueID
        self.uid = uid
        self.originalTime = originalTime
        self.instanceStartTime = instanceStartTime
        self.instanceEndTime = instanceEndTime
    }
}
