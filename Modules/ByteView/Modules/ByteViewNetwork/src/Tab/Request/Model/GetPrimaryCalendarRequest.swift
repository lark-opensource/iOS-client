//
//  GetPrimaryCalendarRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 获取当前用户的精简主日历
/// - Calendar_V1_GetCurrentUserBriefPrimaryCalendarRequest
public struct GetPrimaryCalendarRequest {
    public static let command: NetworkCommand = .rust(.getCurrentUserBriefPrimaryCalendar)
    public typealias Response = GetPrimaryCalendarResponse
    public static let defaultOptions: NetworkRequestOptions? = [.shouldPrintResponse]

    public init() {}
}

/// - Calendar_V1_GetCurrentUserBriefPrimaryCalendarResponse
public struct GetPrimaryCalendarResponse {

    public var calendar: BriefCalendar

    /// - Calendar_V1_Calendar
    public struct BriefCalendar {

        /// 数据库自增id 新建日历时置为空串
        public var id: String

        /// 日历在服务端的唯一id 新建日历时置为空串
        public var serverID: String
    }
}

extension GetPrimaryCalendarRequest: RustRequestWithResponse {
    typealias ProtobufType = Calendar_V1_GetCurrentUserBriefPrimaryCalendarRequest
    func toProtobuf() throws -> Calendar_V1_GetCurrentUserBriefPrimaryCalendarRequest {
        var request = ProtobufType()
        request.needCurrentUser = false
        return request
    }
}

extension GetPrimaryCalendarResponse: RustResponse {
    typealias ProtobufType = Calendar_V1_GetCurrentUserBriefPrimaryCalendarResponse
    init(pb: Calendar_V1_GetCurrentUserBriefPrimaryCalendarResponse) throws {
        self.calendar = BriefCalendar(id: pb.calendar.id, serverID: pb.calendar.serverID)
    }
}
