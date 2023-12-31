//
//  VoIPPushInfo.swift
//  ByteView
//
//  Created by 刘建龙 on 2019/9/2.
//

import Foundation
import ByteViewNetwork

struct VoIPPushInfo: Decodable {
    let userID: String
    let pushType: Int
    let productType: String
    let uuid: String
    let conferenceID: String
    let msgType: String
    let deviceToken: String
    var topic: String
    let inviterID: String
    let hasVideo: Bool

    let role: ParticipantMeetingRole?

    let interactiveID: String
    let apnsExpiration: Date

    let meetingType: MeetingType
    let meetingSource: MeetingSource
    let inviterType: InviterType

    let ringtone: String?

    var sid: String?

    let requestId = UUID()

    init(from decoder: Decoder) throws {
        let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
        let extraContainer = try keyedContainer.nestedContainer(keyedBy: ExtraCodingKeys.self, forKey: .extra)
        sid = try? keyedContainer.decodeIfPresent(String.self, forKey: .sid)
        pushType = try extraContainer.decode(type(of: pushType), forKey: .type)

        let contentContainer = try extraContainer.nestedContainer(keyedBy: ExtraContentCodingKeys.self,
                                                                  forKey: .content)
        productType = try contentContainer.decode(String.self, forKey: .productType)
        uuid = try contentContainer.decode(type(of: uuid), forKey: .uuid)
        conferenceID = try contentContainer.decode(type(of: conferenceID), forKey: .conferenceID)
        msgType = try contentContainer.decode(type(of: msgType), forKey: .msgType)
        deviceToken = try contentContainer.decode(type(of: deviceToken), forKey: .deviceToken)
        topic = try contentContainer.decode(type(of: topic), forKey: .topic)
        inviterID = try contentContainer.decode(type(of: inviterID), forKey: .inviterID)
        inviterType = (try? contentContainer.decode(type(of: inviterType),
                                                    forKey: .inviterType)) ?? 0
        hasVideo = try contentContainer.decode(type(of: hasVideo), forKey: .hasVideo)

        meetingType = (try? contentContainer.decode(type(of: meetingType), forKey: .meetingType)) ?? .unknown
        meetingSource = (try? contentContainer.decode(type(of: meetingSource), forKey: .meetingSource))
            ?? VideoChatInfo.MeetingSource.unknown.rawValue

        interactiveID = (try? contentContainer.decode(type(of: interactiveID), forKey: .interactiveID)) ?? ""

        role = (try? contentContainer.decode(Int.self, forKey: .role)).flatMap(ParticipantMeetingRole.init(rawValue:))

        if let timestamp = try? contentContainer.decode(Int64.self, forKey: .apnsExpiration) {
            apnsExpiration = Date(timeIntervalSince1970: TimeInterval(timestamp + 70))
        } else {
            apnsExpiration = .distantFuture
        }

        userID = try contentContainer.decode(type(of: userID), forKey: .userID)
        ringtone = try? contentContainer.decodeIfPresent(String.self, forKey: .ringtone)
    }

    var isInterview: Bool {
        meetingSource == VideoChatInfo.MeetingSource.vcFromInterview.rawValue
    }

    enum MeetingType: Int, Codable {
        case unknown = 0
        case call = 1
        case meet = 2
    }

    typealias MeetingSource = Int
    typealias InviterType = Int

    enum CodingKeys: String, CodingKey {
        case extra
        case sid
    }

    enum ExtraCodingKeys: String, CodingKey {
        case type
        case content
    }

    enum ExtraContentCodingKeys: String, CodingKey {
        case userID = "user_id"
        case productType = "product_type"
        case uuid = "uuid"
        case conferenceID = "conference_id"
        case msgType = "msg_type"
        case deviceToken = "device_token"
        case topic = "topic"
        case inviterID = "inviter_id"
        case inviterType = "inviter_type"
        case hasVideo = "has_video"
        case meetingType = "meeting_type"
        case meetingSource = "meeting_source"
        case interactiveID = "interactive_id"
        case apnsExpiration = "apns_expiration"
        case role = "role"
        case ringtone = "ringtone"
    }
}

extension VoIPPushInfo: CustomStringConvertible {
    var description: String {
        return """
{
    type: \(pushType),
    sid: \(sid),
    content: {
        user_id: \(userID),
        product_type: \(productType),
        uuid: \(uuid),
        conference_id: \(conferenceID),
        msg_type: \(msgType),
        device_token: \(deviceToken),
        topic: \(topic.hash),
        inviter_id: \(inviterID),
        has_video: \(hasVideo),
        meeting_type: \(meetingType),
        meeting_source: \(meetingSource),
        interactive_id: \(interactiveID),
        apns_expiration: \(apnsExpiration),
        role: \(role),
        ringtone: \(ringtone),
    }
}
"""
    }
}

extension VoIPPushInfo: EntryParams {
    var id: String { conferenceID }

    var source: MeetingEntrySource { .init(rawValue: "voip_push") }

    var entryType: EntryType { .push }

    var isCall: Bool { meetingType == .call }

    var isJoinMeeting: Bool { true }
}

extension VoIPPushInfo.MeetingType {
    var vcType: MeetingType {
        return MeetingType(rawValue: self.rawValue) ?? .unknown
    }
}

extension VoIPPushInfo.MeetingSource {
    var vcType: VideoChatInfo.MeetingSource {
        return VideoChatInfo.MeetingSource(rawValue: self) ?? .unknown
    }
}

extension VoIPPushInfo {
    private init() {
        userID = ""
        pushType = 0
        productType = ""
        uuid = ""
        conferenceID = ""
        msgType = ""
        deviceToken = ""
        topic = ""
        inviterID = ""
        hasVideo = false

        role = nil

        interactiveID = ""
        apnsExpiration = .distantPast

        meetingType = .unknown
        meetingSource = VideoChatInfo.MeetingSource.unknown.rawValue
        inviterType = ParticipantType.unknown.rawValue

        sid = ""
        ringtone = nil
    }

    /// mock 用，字段均为空信息
    static let empty = VoIPPushInfo()
}
