//
//  JoinMeetingByLinkBody.swift
//  ByteViewInterface
//
//  Created by kiri on 2023/6/30.
//

import Foundation

/// 链接入会, /client/videochat/open
public struct JoinMeetingByLinkBody: CodablePathBody {
    /// /client/videochat/open
    public static let path = "/client/videochat/open"

    public let source: Source
    public let action: Action
    public let id: String
    /// for calendar
    public var no: String?
    public var uniqueID: String?
    public var uid: String?
    public var originalTime: Int64?
    public var instanceStartTime: Int64?
    public var instanceEndTime: Int64?
    /// for interview
    public var role: JoinMeetingRole?
    /// for openplatform
    public var idType: OpenPlatformIdType
    public var preview: Bool
    public var candidateid: String?
    public var mic: Bool?
    public var speaker: Bool?
    public var camera: Bool?
    public var isE2Ee: Bool?

    public init(source: Source, action: Action, id: String, no: String? = nil, uniqueID: String? = nil, uid: String? = nil, originalTime: Int64? = nil, instanceStartTime: Int64? = nil, instanceEndTime: Int64? = nil, role: JoinMeetingRole? = nil, idType: OpenPlatformIdType, preview: Bool, candidateid: String? = nil, mic: Bool? = nil, speaker: Bool? = nil, camera: Bool? = nil, isE2Ee: Bool? = nil) {
        self.source = source
        self.action = action
        self.id = id
        self.no = no
        self.uniqueID = uniqueID
        self.uid = uid
        self.originalTime = originalTime
        self.instanceStartTime = instanceStartTime
        self.instanceEndTime = instanceEndTime
        self.role = role
        self.idType = idType
        self.preview = preview
        self.candidateid = candidateid
        self.mic = mic
        self.speaker = speaker
        self.camera = camera
        self.isE2Ee = isE2Ee
    }

    public enum Source: String, Codable {
        case calendar
        case interview
        case openplatform
        case widget
        case peopleplatform
    }

    public enum Action: String, Codable {
        case join
        case call
        case start
        case opentab
    }

    public enum OpenPlatformIdType: String, Codable {
        case uniqueid
        case interviewid
        case reservationid
        case groupid
        case meetingno
        case unknown
    }

    public var calendarInstance: CalendarInstanceIdentifier? {
        if let uniqueID = uniqueID, let uid = uid, let originalTime = originalTime, let startTime = instanceStartTime, let endTime = instanceEndTime {
            return CalendarInstanceIdentifier(uniqueID: uniqueID, uid: uid, originalTime: originalTime, instanceStartTime: startTime, instanceEndTime: endTime)
        }
        return nil
    }
}
