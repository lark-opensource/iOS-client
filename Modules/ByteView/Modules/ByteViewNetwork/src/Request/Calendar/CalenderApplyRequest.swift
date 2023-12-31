//
//  CalenderApplyRequest.swift
//  ByteViewNetwork
//
//  Created by wangpeiran on 2022/1/5.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

public struct GetCalendarDefaultVCSettingsRequest {
    public static let command: NetworkCommand = .server(.getCalendarDefaultSettings)
    public typealias Response = GetCalendarDefaultVCSettingsResponse
    public static var defaultOptions: NetworkRequestOptions? = [.shouldPrintResponse]

    public var userId: String?

    /// 获取webinar最大人数及默认设置，创建者userID从ctx获取
    public var organizerTenantId: Int64?

    public var organizerUserId: Int64?

    public var isWebinar: Bool?

    /// 用于仅获取最大人数的情况（创建webinar日程后再次编辑）
    public var needVcSetting: Bool?

    public init(userId: String? = nil, organizerTenantId: Int64? = nil, organizerUserId: Int64? = nil, isWebinar: Bool? = nil, needVcSetting: Bool? = nil) {
        self.userId = userId
        self.organizerUserId = organizerUserId
        self.organizerTenantId = organizerTenantId
        self.isWebinar = isWebinar
        self.needVcSetting = needVcSetting
    }
}

public struct GetCalendarDefaultVCSettingsResponse {
    public var calendarVcSetting: CalendarSettings
    public var maxParti: Int64
    public var vcSettingStr: String
}

extension GetCalendarDefaultVCSettingsRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_calendar_GetCalendarDefaultSettingsRequest
    func toProtobuf() throws -> ServerPB_Videochat_calendar_GetCalendarDefaultSettingsRequest {
        var request = ProtobufType()
        if let userId = userId {
            request.userID = userId
        }
        if let organizerUserId = organizerUserId {
            request.organizerUserID = organizerUserId
        }
        if let organizerTenantId = organizerTenantId {
            request.organizerTenantID = organizerTenantId
        }
        if let isWebinar = isWebinar {
            request.isWebinar = isWebinar
        }
        if let needVcSetting = needVcSetting {
            request.needVcSetting = needVcSetting
        }
        return request
    }
}

extension GetCalendarDefaultVCSettingsResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_calendar_GetCalendarDefaultSettingsResponse
    init(pb: ServerPB_Videochat_calendar_GetCalendarDefaultSettingsResponse) throws {
        self.calendarVcSetting = pb.calendarVcSetting.vcType
        self.maxParti = pb.maxParti
        self.vcSettingStr = pb.vcSettingStr
    }
}

public struct GetCalendarPreVCSettingsRequest {
    public static let command: NetworkCommand = .server(.getCalendarPreSettings)
    public typealias Response = GetCalendarPreVCSettingsResponse

    public init(vcSettingID: String) {
        self.vcSettingID = vcSettingID
    }
    public var vcSettingID: String
}

public struct GetCalendarPreVCSettingsResponse {
    public var calendarVcSetting: CalendarSettings
}

extension GetCalendarPreVCSettingsRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_calendar_GetCalendarPreSettingsRequest
    func toProtobuf() throws -> ServerPB_Videochat_calendar_GetCalendarPreSettingsRequest {
        var request = ProtobufType()
        request.vcSettingID = vcSettingID
        return request
    }
}

extension GetCalendarPreVCSettingsResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_calendar_GetCalendarPreSettingsResponse
    init(pb: ServerPB_Videochat_calendar_GetCalendarPreSettingsResponse) throws {
        self.calendarVcSetting = pb.calendarVcSetting.vcType
    }
}

public struct ApplyMeetingNORequest {
    public static let command: NetworkCommand = .server(.applyPreVcSettingID)
    public typealias Response = ApplyMeetingNOResponse

    public init(settings: CalendarSettings) {
        self.settings = settings
    }
    public var settings: CalendarSettings
}

public struct ApplyMeetingNOResponse {
    public var vcSettingID: String
}

extension ApplyMeetingNORequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_calendar_ApplyPreVcSettingIdRequest
    func toProtobuf() throws -> ServerPB_Videochat_calendar_ApplyPreVcSettingIdRequest {
        var request = ProtobufType()
        request.calendarVcSetting = settings.toProtobuf()
        return request
    }
}

extension ApplyMeetingNOResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_calendar_ApplyPreVcSettingIdResponse
    init(pb: ServerPB_Videochat_calendar_ApplyPreVcSettingIdResponse) throws {
        self.vcSettingID = pb.vcSettingID
    }
}
