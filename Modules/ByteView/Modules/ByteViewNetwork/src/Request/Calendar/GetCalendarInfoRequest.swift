//
//  GetCalendarInfoRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 获取日历详情 2326
/// - GET_CALENDAR_INFO = 2326
/// - Videoconference_V1_GetCalendarInfoRequest
public struct GetCalendarInfoRequest {
    public static let command: NetworkCommand = .rust(.getCalendarInfo)
    public typealias Response = GetCalendarInfoResponse

    public init(meetingID: String, includeSipBindRoom: Bool) {
        self.meetingID = meetingID
        self.includeSipBindRoom = includeSipBindRoom
    }

    ///meeting id
    public var meetingID: String

    public var includeSipBindRoom: Bool
}

/// Videoconference_V1_GetCalendarInfoResponse
public struct GetCalendarInfoResponse {

    public var calendarInfo: CalendarInfo?
}


extension GetCalendarInfoRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_GetCalendarInfoRequest
    func toProtobuf() throws -> Videoconference_V1_GetCalendarInfoRequest {
        var request = ProtobufType()
        request.meetingID = meetingID
        request.includeSipBindRoom = includeSipBindRoom
        return request
    }
}

extension GetCalendarInfoResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_GetCalendarInfoResponse
    init(pb: Videoconference_V1_GetCalendarInfoResponse) throws {
        self.calendarInfo = pb.hasCalendarInfo ? pb.calendarInfo.vcType : nil
    }
}
