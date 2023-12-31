//
//  GetShareCodeInfoRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - GET_SHARE_CODE_INFO = 2340
/// - ServerPB_Videochat_GetShareCodeInfoRequest
public struct GetShareCodeInfoRequest {
    public static let command: NetworkCommand = .server(.getShareCodeInfo)
    public typealias Response = GetShareCodeInfoResponse

    public init(shareCode: String, roomBindFilter: RoomBindFilter = .none) {
        self.shareCode = shareCode
        self.roomBindFilter = roomBindFilter
    }

    public var shareCode: String
    public var roomBindFilter: RoomBindFilter
}

/// - ServerPB_Videochat_GetShareCodeInfoResponse
public struct GetShareCodeInfoResponse {
    public var user: ByteviewUser?
    public var alreadyInSameMeeting: Bool
    public var statusCode: StatusCode
    public var isRoomInMeeting: Bool = false
    public var isRoomInCalendar: Bool = false
    public var isUserInCalendar: Bool = false

    public init(user: ByteviewUser?, alreadyInSameMeeting: Bool, statusCode: StatusCode) {
        self.user = user
        self.alreadyInSameMeeting = alreadyInSameMeeting
        self.statusCode = statusCode
    }

    public enum StatusCode: String, CustomStringConvertible {
        case unknown
        case success
        /// 会议室本身不可用，未认证等情况
        case roomUnavailable
        /// 会议室被占用，已在其他会议
        case roomTaken
        /// 需要输入投屏码校验/
        case roomNeedVerify

        public var description: String { rawValue }
    }
}

extension GetShareCodeInfoRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_GetShareCodeInfoRequest
    func toProtobuf() throws -> ServerPB_Videochat_GetShareCodeInfoRequest {
        var request = ProtobufType()
        request.shareCode = shareCode
        switch roomBindFilter {
        case let .generic(joinType):
            request.filterType = .genericJoin
            let (t, handle) = joinType.serverPbType
            request.genericFilter = .init()
            request.genericFilter.joinType = t
            request.genericFilter.joinHandle = handle
        case .calendar(let uniqueId):
            request.filterType = .calendarJoin
            request.calendarFilter = .init()
            request.calendarFilter.uniqueID = uniqueId
        case .interview(let uniqueId):
            request.filterType = .interviewJoin
            request.interviewFilter = .init()
            request.interviewFilter.uniqueID = uniqueId
        case .none:
            request.filterType = .none
        }
        return request
    }
}

extension GetShareCodeInfoResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_GetShareCodeInfoResponse
    init(pb: ServerPB_Videochat_GetShareCodeInfoResponse) throws {
        self.user = pb.hasUser ? pb.user.vcType : nil
        self.alreadyInSameMeeting = pb.alreadyInSameMeeting
        self.isRoomInMeeting = pb.isRoomInMeeting
        self.isRoomInCalendar = pb.isRoomInCalendar
        self.isUserInCalendar = pb.isUserInCalendar
        switch pb.statusCode {
        case .success:
            self.statusCode = .success
        case .roomUnavailable:
            self.statusCode = .roomUnavailable
        case .roomTaken:
            self.statusCode = .roomTaken
        case .roomNeedVerify:
            self.statusCode = .roomNeedVerify
        @unknown default:
            self.statusCode = .unknown
        }
    }
}

extension GetShareCodeInfoRequest {

    public enum RoomBindFilter: Equatable {
        case none
        case generic(JoinMeetingRequest.JoinType)
        /// uniqueId
        case calendar(String)
        /// uniqueId
        case interview(String)
    }
}

extension JoinMeetingRequest.JoinType {
    typealias ServerJoinMeetingRequest = ServerPB_Videochat_JoinMeetingRequest

    var serverPbType: (ServerJoinMeetingRequest.JoinType, ServerJoinMeetingRequest.Handle) {
        var handle = ServerJoinMeetingRequest.Handle()
        switch self {
        case .meetingId(let voucher, _):
            handle.meetingID = voucher
            return (.joinVcViaMeetingID, handle)
        case .groupId(let voucher):
            handle.groupID = voucher
            return (.joinVcViaGroupID, handle)
        case .meetingNumber(let voucher):
            handle.meetingNo = voucher
            return (.joinVcViaMeetingNumber, handle)
        case .reserveId(let voucher):
            handle.uniqueID = voucher
            return (.joinVcViaReserveID, handle)
        default:
            handle.uniqueID = ""
            return (.joinVcViaReserveID, handle)
        }
    }
}
