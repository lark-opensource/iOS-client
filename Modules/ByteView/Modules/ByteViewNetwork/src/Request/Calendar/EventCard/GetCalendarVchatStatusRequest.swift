//
//  GetCalendarVchatStatusRequest.swift
//  ByteViewNetwork
//
//  Created by lutingting on 2023/8/3.
//

import Foundation
import ServerPB

/// ServerPB.ServerPB_Videochat_GetCalendarVchatStatusRequest
public struct GetCalendarVchatStatusRequest {
    public static var command: NetworkCommand = .server(.getCalendarVchatStatus)
    public typealias Response = GetCalendarVchatStatusResponse

    public var uniqueID: Int64
    public var calendarInstanceIdentifier: CalendarInstanceIdentifier
    /// 客户端传递的身份。如果为观众，不再调用日历判断(由于观众权限小于嘉宾)
    public var isAudience: Bool

    public init(uniqueID: Int64, calendarInstanceIdentifier: CalendarInstanceIdentifier, isAudience: Bool) {
        self.uniqueID = uniqueID
        self.calendarInstanceIdentifier = calendarInstanceIdentifier
        self.isAudience = isAudience
    }
}

/// ServerPB_Videochat_GetCalendarVchatStatusResponse
public struct GetCalendarVchatStatusResponse {
    public var videoChatStatus: CalendarVideoChatStatus
}

public struct CalendarVideoChatStatus {
    public var uniqueID: Int64
    public var status: Status
    public var startTime: Int64
    public var meetingID: Int64
    public var meetingDuration: Int64
    public var requestBeginTime: Int64
    public var requestEndTime: Int64
    public var tenantID: Int64
    /// 彩排模式开关
    public var rehearsalMode: Bool
    /// 当前会议是否在彩排中
    public var isRehearsal: Bool

    public enum Status: Int {
        case unknown
        case live
        case notLive
    }
}

extension CalendarVideoChatStatus {
    init(serverPB: ServerPB_Videochat_CalendarVideoChatStatus) {
        self.uniqueID = serverPB.uniqueID
        self.status = .init(rawValue: serverPB.status.rawValue) ?? .unknown
        self.startTime = serverPB.startTime
        self.meetingID = serverPB.meetingID
        self.meetingDuration = serverPB.meetingDuration
        self.requestBeginTime = serverPB.requestBeginTime
        self.requestEndTime = serverPB.requestEndTime
        self.tenantID = serverPB.tenantID
        self.rehearsalMode = serverPB.rehearsalMode
        self.isRehearsal = serverPB.isRehearsal
    }

    var serverPBType: ServerPB_Videochat_CalendarVideoChatStatus {
        var identifier = ServerPB_Videochat_CalendarVideoChatStatus()
        identifier.uniqueID = uniqueID
        identifier.status = .init(rawValue: status.rawValue) ?? .unknown
        identifier.startTime = startTime
        identifier.meetingID = meetingID
        identifier.meetingDuration = meetingDuration
        identifier.requestBeginTime = requestBeginTime
        identifier.requestEndTime = requestEndTime
        identifier.tenantID = tenantID
        identifier.rehearsalMode = rehearsalMode
        identifier.isRehearsal = isRehearsal
        return identifier
    }
}


extension GetCalendarVchatStatusRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_GetCalendarVchatStatusRequest
    func toProtobuf() throws -> ServerPB_Videochat_GetCalendarVchatStatusRequest {
        var request = ProtobufType()
        request.uniqueID = uniqueID
        request.calendarInstanceIdentifier = calendarInstanceIdentifier.serverPBType
        request.isAudience = isAudience
        return request
    }
}

extension GetCalendarVchatStatusResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_GetCalendarVchatStatusResponse
    init(pb: ServerPB_Videochat_GetCalendarVchatStatusResponse) throws {
        self.videoChatStatus = .init(serverPB: pb.videoChatStatus)
    }
}
