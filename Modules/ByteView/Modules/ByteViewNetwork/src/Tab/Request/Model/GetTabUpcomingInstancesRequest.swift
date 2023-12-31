//
//  GetTabUpcomingInstancesResponse.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - GET_VC_UPCOMING_CALENDAR_INSTANCES = 89363
/// - Videoconference_V1_GetVCUpcomingCalendarInstancesRequest
public struct GetTabUpcomingInstancesRequest {
    public static let command: NetworkCommand = .rust(.getVcUpcomingCalendarInstances)
    public typealias Response = GetTabUpcomingInstancesResponse
    public static let defaultOptions: NetworkRequestOptions? = [.shouldPrintResponse]

    public init(startTime: Int64?, number: Int64?) {
        self.startTime = startTime
        self.number = number
    }

    /// 开始时间(毫秒时间戳)
    public var startTime: Int64?

    /// 数量(目前PC=3,pad和mobile=2，保证接口灵活)
    public var number: Int64?

    /// 时区
    public var timezone: String = TimeZone.current.identifier
}

/// Videoconference_V1_GetVCUpcomingCalendarInstancesResponse
public struct GetTabUpcomingInstancesResponse: CustomStringConvertible {

    public var instances: [TabUpcomingInstance]

    public var description: String {
        String(indent: "GetTabUpcomingInstancesResponse", "instances: \(instances.map({ $0.uniqueID }))")
    }
}

extension GetTabUpcomingInstancesRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_GetVCUpcomingCalendarInstancesRequest
    func toProtobuf() throws -> Videoconference_V1_GetVCUpcomingCalendarInstancesRequest {
        var request = ProtobufType()
        if let startTime = startTime {
            request.startTime = startTime
        }
        if let number = number {
            request.number = number
        }
        request.timezone = timezone
        return request
    }
}

extension GetTabUpcomingInstancesResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_GetVCUpcomingCalendarInstancesResponse
    init(pb: Videoconference_V1_GetVCUpcomingCalendarInstancesResponse) throws {
        self.instances = pb.instances.map({ $0.vcType })
    }
}
