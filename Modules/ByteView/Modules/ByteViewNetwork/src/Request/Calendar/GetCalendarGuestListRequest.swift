//
//  GetCalendarGuestListRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - GET_CALENDAR_GUEST_LIST
/// - Videoconference_V1_GetCalendarGuestListByMeetingIDRequest
public struct GetCalendarGuestListRequest {
    public static let command: NetworkCommand = .rust(.getCalendarGuestList)
    public typealias Response = GetCalendarGuestListResponse

    public init(meetingID: String) {
        self.meetingID = meetingID
    }

    public var meetingID: String
}

/// Videoconference_V1_GetCalendarGuestListByMeetingIDResponse
public struct GetCalendarGuestListResponse {
    public init(status: Status, resultList: [Result]) {
        self.status = status
        self.resultList = resultList
    }

    public var status: Status

    public var resultList: [Result]

    public enum Status: Int, Hashable {
        case unknown // = 0
        case success // = 1
        case notInCalendar // = 2
        case noPermission // = 3
    }

    public struct LarkUserInfo {

        public var userName: String

        public var avatarKey: String

        public var department: String

        public var crossTenant: Bool
    }

    public struct RoomUserInfo {
        public init(fullName: String, avatarKey: String, location: RoomLocation) {
            self.fullName = fullName
            self.avatarKey = avatarKey
            self.location = location
        }

        /// 完整拼接的会议室名字
        public var fullName: String

        public var avatarKey: String

        /// 会议室位置信息
        public var location: RoomLocation
    }

    public struct ChatInfo {
        public init(chatID: Int64, chatName: String, avatarKey: String, crossTenant: Bool, memberCount: Int64) {
            self.chatID = chatID
            self.chatName = chatName
            self.avatarKey = avatarKey
            self.crossTenant = crossTenant
            self.memberCount = memberCount
        }

        public var chatID: Int64

        public var chatName: String

        public var avatarKey: String

        public var crossTenant: Bool

        public var memberCount: Int64
    }

    public struct Result {
        public init(user: ByteviewUser, larkUserInfo: LarkUserInfo?, roomUserInfo: RoomUserInfo?, chatInfo: ChatInfo?) {
            self.user = user
            self.larkUserInfo = larkUserInfo
            self.roomUserInfo = roomUserInfo
            self.chatInfo = chatInfo
        }

        public var user: ByteviewUser

        public var larkUserInfo: LarkUserInfo?

        public var roomUserInfo: RoomUserInfo?

        public var chatInfo: ChatInfo?
    }
}

extension GetCalendarGuestListRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_GetCalendarGuestListByMeetingIDRequest
    func toProtobuf() throws -> Videoconference_V1_GetCalendarGuestListByMeetingIDRequest {
        var request = ProtobufType()
        request.meetingID = meetingID
        return request
    }
}

extension GetCalendarGuestListResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_GetCalendarGuestListByMeetingIDResponse
    init(pb: Videoconference_V1_GetCalendarGuestListByMeetingIDResponse) throws {
        self.status = .init(rawValue: pb.status.rawValue) ?? .unknown
        self.resultList = pb.resultList.map({ .init(pb: $0) })
    }
}

extension GetCalendarGuestListResponse.Result: ProtobufDecodable {
    typealias ProtobufType = Videoconference_V1_GetCalendarGuestListByMeetingIDResponse.Result
    init(pb: Videoconference_V1_GetCalendarGuestListByMeetingIDResponse.Result) {
        self.user = pb.user.vcType
        self.larkUserInfo = pb.hasLarkUserInfo ? .init(pb: pb.larkUserInfo) : nil
        self.roomUserInfo = pb.hasRoomUserInfo ? .init(pb: pb.roomUserInfo) : nil
        self.chatInfo = pb.hasChatInfo ? .init(pb: pb.chatInfo) : nil
    }
}

extension GetCalendarGuestListResponse.LarkUserInfo: ProtobufDecodable {
    typealias ProtobufType = Videoconference_V1_GetCalendarGuestListByMeetingIDResponse.LarkUserInfo
    init(pb: Videoconference_V1_GetCalendarGuestListByMeetingIDResponse.LarkUserInfo) {
        self.userName = pb.userName
        self.avatarKey = pb.avatarKey
        self.department = pb.department
        self.crossTenant = pb.crossTenant
    }
}

extension GetCalendarGuestListResponse.RoomUserInfo: ProtobufDecodable {
    typealias ProtobufType = Videoconference_V1_GetCalendarGuestListByMeetingIDResponse.RoomUserInfo
    init(pb: Videoconference_V1_GetCalendarGuestListByMeetingIDResponse.RoomUserInfo) {
        self.fullName = pb.fullName
        self.avatarKey = pb.avatarKey
        let location = pb.location
        self.location = .init(floorName: location.floorName, buildingName: location.buildingName)
    }
}

extension GetCalendarGuestListResponse.ChatInfo: ProtobufDecodable {
    typealias ProtobufType = Videoconference_V1_GetCalendarGuestListByMeetingIDResponse.ChatInfo
    init(pb: Videoconference_V1_GetCalendarGuestListByMeetingIDResponse.ChatInfo) {
        self.chatID = pb.chatID
        self.chatName = pb.chatName
        self.avatarKey = pb.avatarKey
        self.crossTenant = pb.crossTenant
        self.memberCount = pb.memberCount
    }
}
