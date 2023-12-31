//
//  SearchUserInMeetingRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/4.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// Videoconference_V1_VCSearchUserInMeetingRequest
/// - VC_LARK_SEARCH_USER_IN_MEETING = 89306
public struct SearchParticipantRequest {
    public static let command: NetworkCommand = .rust(.vcLarkSearchUserInMeeting)
    public typealias Response = SearchParticipantResponse

    public init(meetingId: String, breakoutRoomId: String?, query: String, count: Int, queryType: QueryType) {
        self.meetingId = meetingId
        self.breakoutRoomId = breakoutRoomId
        self.query = query
        self.count = count
        self.queryType = queryType
    }

    public var meetingId: String

    public var breakoutRoomId: String?

    public var query: String

    public var count: Int

    public var queryType: QueryType

    public enum QueryType: Int, Equatable {
        case queryAll // = 0
        case queryInMeeting // = 1
    }
}

/// Videoconference_V1_VCSearchUserInMeetingResponse
public struct SearchParticipantResponse: CustomNetworkResponse {
    public typealias CustomContext = SearchParticipantRequest

    public init(users: [SearchResult]) {
        self.users = users
    }

    public var users: [SearchResult]

    public struct SearchResult {
        public init(name: String, avatarKey: String, user: ByteviewUser, status: UserStatus,
                    participant: Participant?, lobby: LobbyParticipant?, larkUserInfo: LarkUserInfo?,
                    roomInfo: RoomInfo?, sipInfo: SipInfo?) {
            self.name = name
            self.avatarKey = avatarKey
            self.user = user
            self.status = status
            self.participant = participant
            self.lobby = lobby
            self.larkUserInfo = larkUserInfo
            self.roomInfo = roomInfo
            self.sipInfo = sipInfo
        }

        public var name: String

        public var avatarKey: String

        public var user: ByteviewUser

        public var status: UserStatus

        ///  userStatus为IN_MEETING时使用
        public var participant: Participant?

        ///  userStatus为IN_LOBBY时使用
        public var lobby: LobbyParticipant?

        ///  userStatus为NOT_IN_MEETING且userType为larkUser时使用
        public var larkUserInfo: LarkUserInfo?

        ///  userStatus为NOT_IN_MEETING且userType为RoomUser时使用
        public var roomInfo: RoomInfo?

        /// SIP设备信息, userType == SIP 时使用
        public var sipInfo: SipInfo?
    }

    public enum UserStatus: Int, Equatable {
        case unknown // = 0
        case inMeeting // = 1
        case inLobby // = 2
        case notInMeeting // = 3
    }

    public struct SipInfo {
        public init(address: String, primaryName: String, secondaryName: String) {
            self.address = address
            self.primaryName = primaryName
            self.secondaryName = secondaryName
        }

        public var address: String

        public var primaryName: String

        public var secondaryName: String
    }

    public struct LarkUserInfo {
        public init(department: String, workStatus: User.WorkStatus, crossTenant: Bool, versionSupport: Bool,
                    executiveMode: Bool, collaborationType: LarkUserCollaborationType,
                    customStatuses: [User.CustomStatus]) {
            self.department = department
            self.workStatus = workStatus
            self.crossTenant = crossTenant
            self.executiveMode = executiveMode
            self.versionSupport = versionSupport
            self.collaborationType = collaborationType
            self.customStatuses = customStatuses
        }

        public var department: String

        public var workStatus: User.WorkStatus

        public var crossTenant: Bool

        public var versionSupport: Bool

        public var executiveMode: Bool

        /// 目标用户与发起搜索用户之间的协作关系
        public var collaborationType: LarkUserCollaborationType

        /// 自定义个人状态，start_time升序
        public var customStatuses: [User.CustomStatus]
    }

    public struct RoomInfo {
        public init(capacity: Int, location: RoomLocation,
                    fullName: String, fullNameParticipant: String, fullNameSite: String,
                    primaryNameParticipant: String, primaryNameSite: String, secondaryName: String,
                    isRoomBusy: Bool) {
            self.capacity = capacity
            self.location = location
            self.fullName = fullName
            self.fullNameParticipant = fullNameParticipant
            self.fullNameSite = fullNameSite
            self.primaryNameParticipant = primaryNameParticipant
            self.primaryNameSite = primaryNameSite
            self.secondaryName = secondaryName
            self.isRoomBusy = isRoomBusy
        }

        /// 容纳人数
        public var capacity: Int

        /// 会议室位置信息
        public var location: RoomLocation

        /// 完整拼接的会议室名字
        public var fullName: String

        /// 会议室拼接名
        public var fullNameParticipant: String

        /// 会议室拼接名
        public var fullNameSite: String

        /// 会议室拼接名
        public var primaryNameParticipant: String

        /// 会议室拼接名
        public var primaryNameSite: String

        /// 会议室拼接名
        public var secondaryName: String

        /// 会议室是否忙线
        public var isRoomBusy: Bool
    }
}

extension SearchParticipantRequest: RustRequestWithCustomResponse {
    typealias ProtobufType = Videoconference_V1_VCSearchUserInMeetingRequest
    func toProtobuf() throws -> Videoconference_V1_VCSearchUserInMeetingRequest {
        var request = ProtobufType()
        request.query = query
        request.count = Int32(count)
        request.queryType = .init(rawValue: queryType.rawValue) ?? .queryAll
        if let id = RequestUtil.normalizedBreakoutRoomId(breakoutRoomId) {
            request.breakoutRoomID = id
        }
        return request
    }
}

extension SearchParticipantResponse: _CustomNetworkDecodable {
    typealias ProtobufType = Videoconference_V1_VCSearchUserInMeetingResponse
    init(pb: Videoconference_V1_VCSearchUserInMeetingResponse, context: SearchParticipantRequest) throws {
        self.users = pb.users.map({ $0.vcType(meetingId: context.meetingId) })
    }
}

private typealias PBSearchParticipantResponse = SearchParticipantResponse.ProtobufType

private extension PBSearchParticipantResponse.SearchResult {
    func vcType(meetingId: String) -> SearchParticipantResponse.SearchResult {
        .init(name: name, avatarKey: avatarKey, user: user.vcType,
              status: .init(rawValue: status.rawValue) ?? .unknown,
              participant: hasParticipant ? participant.vcType(meetingID: meetingId) : nil,
              lobby: hasLobby ? lobby.vcType : nil, larkUserInfo: hasLarkUserInfo ? larkUserInfo.vcType : nil,
              roomInfo: hasRoomInfo ? roomInfo.vcType : nil,
              sipInfo: hasSipInfo ? sipInfo.vcType : nil)
    }
}

private extension PBSearchParticipantResponse.LarkUserInfo {
    var vcType: SearchParticipantResponse.LarkUserInfo {
        .init(department: department, workStatus: workStatus.vcType,
              crossTenant: crossTenant, versionSupport: versionSupport, executiveMode: executiveMode,
              collaborationType: .init(rawValue: collaborationType.rawValue) ?? .default,
              customStatuses: customStatuses)
    }
}

private extension PBSearchParticipantResponse.LarkUserInfo.UserWorkStatusType {
    var vcType: User.WorkStatus {
        switch self {
        case .onMeeting:
            return .meeting
        case .onLeave:
            return .leave
        case .onBusiness:
            return .business
        default:
            return .default
        }
    }
}

private extension PBSearchParticipantResponse.RoomInfo {
    var vcType: SearchParticipantResponse.RoomInfo {
        .init(capacity: Int(capacity), location: location.vcType, fullName: fullName,
              fullNameParticipant: fullNameParticipant, fullNameSite: fullNameSite,
              primaryNameParticipant: primaryNameParticipant, primaryNameSite: primaryNameSite,
              secondaryName: secondaryName, isRoomBusy: isRoomBusy)
    }
}

private extension PBSearchParticipantResponse.RoomInfo.Location {
    var vcType: RoomLocation {
        .init(floorName: floorName, buildingName: buildingName)
    }
}

private extension PBSearchParticipantResponse.SipInfo {
    var vcType: SearchParticipantResponse.SipInfo {
        .init(address: address, primaryName: displayNameForMobile.primaryName,
              secondaryName: displayNameForMobile.secondaryName)
    }
}

extension SearchParticipantRequest: CustomStringConvertible {
    public var description: String {
        String(name: "SearchParticipantRequest", [
            "meetingId": meetingId,
            "breakoutRoomId": breakoutRoomId,
            "query.hash": query.hash,
            "count": count,
            "queryType": queryType
        ])
    }
}
