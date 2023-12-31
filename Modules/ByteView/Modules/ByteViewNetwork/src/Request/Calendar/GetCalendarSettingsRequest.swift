//
//  GetCalendarSettingsRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// 查询日程VC配置信息
/// - GET_CALENDAR_VC_SETTINGS = 89352
/// - ServerPB_Videochat_calendar_GetCalendarVCSettingsRequest
public struct GetCalendarSettingsRequest {
    public static let command: NetworkCommand = .server(.getCalendarVcSettings)
    public typealias Response = GetCalendarSettingsResponse

    public init(uniqueID: String, calendarInstanceIdentifier: CalendarInstanceIdentifier) {
        self.uniqueID = uniqueID
        self.calendarInstanceIdentifier = calendarInstanceIdentifier
    }

    public var uniqueID: String

    public var calendarInstanceIdentifier: CalendarInstanceIdentifier
}

/// ServerPB_Videochat_calendar_GetCalendarVCSettingsRequest
public struct GetCalendarSettingsResponse {

    public var settings: CalendarSettings
}

extension GetCalendarSettingsRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_calendar_GetCalendarVCSettingsRequest
    func toProtobuf() throws -> ServerPB_Videochat_calendar_GetCalendarVCSettingsRequest {
        var request = ProtobufType()
        request.uniqueID = uniqueID
        request.calendarInstanceIdentifier = calendarInstanceIdentifier.serverPBType
        return request
    }
}

extension GetCalendarSettingsResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_calendar_GetCalendarVCSettingsResponse
    init(pb: ServerPB_Videochat_calendar_GetCalendarVCSettingsResponse) throws {
        self.settings = .init(pb: pb.settings)
        self.settings.isOrganizer = pb.isOrganizer
        self.settings.intelligentMeetingSetting = pb.settings.intelligentMeetingSetting.vcType
    }
}
