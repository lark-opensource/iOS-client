//
//  SetCalendarSettingsRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// 新增或者修改日程VC配置信息
/// - SET_CALENDAR_VC_SETTINGS = 89351
/// - ServerPB_Videochat_calendar_SetCalendarVCSettingsRequest
public struct SetCalendarSettingsRequest {
    public static let command: NetworkCommand = .server(.setCalendarVcSettings)

    public init(uniqueID: String, settings: CalendarSettings, calendarInstanceIdentifier: CalendarInstanceIdentifier) {
        self.uniqueID = uniqueID
        self.settings = settings
        self.calendarInstanceIdentifier = calendarInstanceIdentifier
    }

    public var uniqueID: String

    public var settings: CalendarSettings

    public var calendarInstanceIdentifier: CalendarInstanceIdentifier
}

extension SetCalendarSettingsRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_calendar_SetCalendarVCSettingsRequest
    func toProtobuf() throws -> ServerPB_Videochat_calendar_SetCalendarVCSettingsRequest {
        var request = ProtobufType()
        request.uniqueID = uniqueID
        request.settings = settings.toProtobuf()
        request.calendarInstanceIdentifier = calendarInstanceIdentifier.serverPBType
        return request
    }
}
