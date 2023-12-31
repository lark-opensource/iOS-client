//
//  GetPstnSipFeatureConfigRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - ServerPB_Videochat_GetPstnSipFeatureConfigRequest
public struct GetPstnSipFeatureConfigRequest {
    public static let command: NetworkCommand = .server(.getPstnSipFc)
    public typealias Response = GetPstnSipFeatureConfigResponse

    public init(userId: Int64, uniqueId: Int64, tenantId: String, isInterview: Bool, calendarInstance: CalendarInstanceIdentifier) {
        self.userId = userId
        self.uniqueId = uniqueId
        self.tenantId = tenantId
        self.isInterview = isInterview
        self.calendarInstanceIdentifier = calendarInstance
    }

    public var userId: Int64

    public var uniqueId: Int64

    public var tenantId: String

    public var isInterview: Bool

    public var calendarInstanceIdentifier: CalendarInstanceIdentifier
}

/// - ServerPB_Videochat_GetPstnSipFeatureConfigResponse
public struct GetPstnSipFeatureConfigResponse {

    public var pstn: Pstn
    public var sip: Sip

    public struct Pstn {

        public var outGoingCallEnable: Bool

        public var incomingCallEnable: Bool
    }

    public struct Sip {

        public var outGoingCallEnable: Bool

        public var incomingCallEnable: Bool
    }
}

extension GetPstnSipFeatureConfigRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_GetPstnSipFeatureConfigRequest
    func toProtobuf() throws -> ServerPB_Videochat_GetPstnSipFeatureConfigRequest {
        var request = ProtobufType()
        request.userID = userId
        request.uniqueID = uniqueId
        request.tenantID = Int64(tenantId) ?? 0
        request.calendarType = isInterview ? .interview : .unknown
        request.calendarInstanceIdentifier = calendarInstanceIdentifier.serverPBType
        return request
    }
}

extension GetPstnSipFeatureConfigResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_GetPstnSipFeatureConfigResponse
    init(pb: ServerPB_Videochat_GetPstnSipFeatureConfigResponse) throws {
        let fc = pb.featureConfig
        self.pstn = Pstn(outGoingCallEnable: fc.pstn.outGoingCallEnable, incomingCallEnable: fc.pstn.incomingCallEnable)
        self.sip = Sip(outGoingCallEnable: fc.sip.outGoingCallEnable, incomingCallEnable: fc.sip.incomingCallEnable)
    }
}
