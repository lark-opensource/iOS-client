//
//  CreateTabMeetingStatisticsRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// 独立tab生成会议统计表格
/// - CREATE_VC_TAB_MEETING_STATISTICS = 89212
/// - ServerPB_Videochat_tab_v2_CreateVCTabMeetingStatisticsRequest
public struct CreateTabMeetingStatisticsRequest {
    public static let command: NetworkCommand = .server(.createVcTabMeetingStatistics)

    public init(meetingId: String, isTwelveHourTime: Bool, locale: String) {
        self.meetingId = meetingId
        self.isTwelveHourTime = isTwelveHourTime
        self.locale = locale
    }

    public var meetingId: String

    public var isTwelveHourTime: Bool

    public var locale: String

    public var timeZone: String = TimeZone.current.identifier
}

extension CreateTabMeetingStatisticsRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_tab_v2_CreateVCTabMeetingStatisticsRequest
    func toProtobuf() throws -> ServerPB_Videochat_tab_v2_CreateVCTabMeetingStatisticsRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.timeZone = timeZone
        request.isTwelveHourTime = isTwelveHourTime
        request.locale = locale
        return request
    }
}
