//
//  GetSuiteQuotaRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// Videoconference_V1_GetSuiteQuotaRequest
public struct GetSuiteQuotaRequest: Equatable {
    public static let command: NetworkCommand = .rust(.vcGetSuiteQuota)
    public typealias Response = GetSuiteQuotaResponse
    public static let defaultOptions: NetworkRequestOptions? = [.shouldPrintResponse]

    /// - parameter meetingID: 客户端传meeting_id时, 服务端返回该会议的owner所属租户的quota
    public init(meetingID: String?) {
        self.meetingID = meetingID
    }

    /// 客户端传meeting_id时, 服务端返回该会议的owner所属租户的quota
    public var meetingID: String?
}

/// Videoconference_V1_GetSuiteQuotaResponse
public struct GetSuiteQuotaResponse: Equatable {

    /// 等候室
    public var waitingRoom: Bool

    /// 同传
    public var interpretation: Bool

    /// pstn呼叫剩余
    public var pstnCall: Bool

    /// 字幕
    public var subtitle: Bool

    /// 分组会议
    public var breakoutRoom: Bool

    /// 是否有pstn精细化余额
    public var pstnRefinedQuota: Bool

    /// 是否有网络研讨会
    public var webinar: Bool

    public init() {
        self.waitingRoom = false
        self.interpretation = false
        self.pstnCall = false
        self.subtitle = true
        self.breakoutRoom = false
        self.pstnRefinedQuota = false
        self.webinar = false
    }
}

extension GetSuiteQuotaRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_GetSuiteQuotaRequest

    func toProtobuf() throws -> Videoconference_V1_GetSuiteQuotaRequest {
        var request = ProtobufType()
        if let id = meetingID {
            request.meetingID = id
        }
        return request
    }
}

extension GetSuiteQuotaResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_GetSuiteQuotaResponse

    init(pb: Videoconference_V1_GetSuiteQuotaResponse) throws {
        self.waitingRoom = pb.waitingRoom
        self.interpretation = pb.interpretation
        self.pstnCall = pb.pstnCall
        self.subtitle = pb.subtitle
        self.breakoutRoom = pb.breakoutRoom
        self.pstnRefinedQuota = pb.pstnRefinedQuota
        self.webinar = pb.webinar
    }
}
