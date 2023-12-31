//
//  PullVCCardInfoResponse.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB
import RustPB

/// 拉取卡片信息
/// - VC_PULL_CARD_INFO = 89309
/// - ServerPB_Videochat_PullVCCardInfoRequest
public struct PullCardInfoRequest {
    public static let command: NetworkCommand = .server(.vcPullCardInfo)
    public typealias Response = PullCardInfoResponse

    public init(meetingId: String, chatId: String?, nextRequestToken: String?) {
        self.meetingId = meetingId
        self.chatId = chatId
        self.nextRequestToken = nextRequestToken
    }

    public var meetingId: String

    public var chatId: String?

    public var nextRequestToken: String?

}

/// ServerPB_Videochat_PullVCCardInfoResponse
public struct PullCardInfoResponse {

    public var videoChatContent: VideoChatContent

    public var nextRequestToken: String

    public var isMore: Bool

    /// ServerPB_Entities_VideoChatContent
    public struct VideoChatContent {

        public var type: VideoChatContent.TypeEnum

        public var meetingCard: MeetingCard

        public enum TypeEnum: Int, Hashable {
            case unknown // = 0
            case meetingCard // = 1
            case chatRoomCard // = 2
            case samePageMeeting // = 3
        }
    }

    public struct MeetingCard {

        /// 点击加入时，需要传给服务端的信息
        public var meetingID: String

        public var status: Status

        public var topic: String

        public var sponsorID: String

        public var hostID: String

        public var meetNumber: String

        public var participants: [MeetingParticipant]
        public var meetingSubType: Int32

        public enum Status: Int, Hashable {
            case unknown // = 0
            case joinable // = 1
            case full // = 2
            case end // = 3
        }
    }

    public struct MeetingParticipant {

        public var meetingID: String

        public var userID: String

        public var userType: ParticipantType

        public var deviceID: String

        public var deviceType: Participant.DeviceType

        public var status: Participant.Status

        public var tenantID: String

        public var tenantTag: TenantTag

        public var bindID: String

        public var bindType: PSTNInfo.BindType

        public var isLarkGuest: Bool

        public var joinTimeMs: Int64

        public var usedCallMe: Bool
    }
}

extension PullCardInfoRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_PullVCCardInfoRequest
    func toProtobuf() throws -> ServerPB_Videochat_PullVCCardInfoRequest {
        var request = ProtobufType()
        request.id = meetingId
        if let id = chatId {
            request.chatID = id
        }
        if let token = nextRequestToken {
            request.nextRequestToken = token
        }
        return request
    }
}

extension PullCardInfoResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_PullVCCardInfoResponse
    init(pb: ServerPB_Videochat_PullVCCardInfoResponse) throws {
        self.videoChatContent = pb.videoChatContent.vcType
        self.nextRequestToken = pb.nextRequestToken
        self.isMore = pb.isMore
    }
}

private typealias PBVideoChatContent = ServerPB_Entities_VideoChatContent
private extension PBVideoChatContent {
    var vcType: PullCardInfoResponse.VideoChatContent {
        .init(type: .init(rawValue: type.rawValue) ?? .unknown, meetingCard: meetingCard.vcType)
    }
}

private extension PBVideoChatContent.MeetingCard {
    var vcType: PullCardInfoResponse.MeetingCard {
        .init(meetingID: meetingID, status: .init(rawValue: status.rawValue) ?? .unknown, topic: topic,
              sponsorID: sponsorID, hostID: hostID, meetNumber: meetNumber,
              participants: participants.map({ $0.vcType(meetingId: meetingID) }),
              meetingSubType: meetingSubType)
    }
}

private extension PBVideoChatContent.MeetingCard.MeetingParticipant {
    func vcType(meetingId: String) -> PullCardInfoResponse.MeetingParticipant {
        return .init(meetingID: meetingId, userID: userID, userType: .init(rawValue: userType.rawValue),
              deviceID: deviceID, deviceType: .init(rawValue: deviceType.rawValue) ?? .unknown,
              status: .init(rawValue: status.rawValue) ?? .unknown,
              tenantID: tenantID, tenantTag: .init(rawValue: tenantTag.rawValue) ?? .standard,
              bindID: bindID, bindType: .init(rawValue: bindType.rawValue) ?? .unknown,
              isLarkGuest: isLarkGuest, joinTimeMs: joinTimeMs, usedCallMe: usedCallMe)
    }
}
