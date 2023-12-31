//
//  GetNtpTimeRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - GETNTPTIME
/// - Tool_V1_GetNTPTimeRequest
public struct GetNtpTimeRequest {
    public static let command: NetworkCommand = .rust(.getNtpTime)
    public typealias Response = GetNtpTimeResponse

    /// 指定是否阻塞到更新成功
    public var blockUntilUpdate: Bool

    public init(blockUntilUpdate: Bool = false) {
        self.blockUntilUpdate = blockUntilUpdate
    }
}

/// Tool_V1_GetNTPTimeResponse
public struct GetNtpTimeResponse {

    public var ntpTime: Int64
    /// ntp_time - now
    public var ntpOffset: Int64
    /// 是否更新成功
    public var hasUpdated: Bool
}

extension GetNtpTimeRequest: RustRequestWithResponse {
    typealias ProtobufType = Tool_V1_GetNTPTimeRequest

    func toProtobuf() throws -> Tool_V1_GetNTPTimeRequest {
        var request = Tool_V1_GetNTPTimeRequest()
        request.blockUntilUpdate = blockUntilUpdate
        return request
    }
}

extension GetNtpTimeResponse: RustResponse {
    typealias ProtobufType = Tool_V1_GetNTPTimeResponse

    init(pb: Tool_V1_GetNTPTimeResponse) throws {
        self.ntpTime = pb.ntpTime
        self.ntpOffset = pb.ntpOffset
        self.hasUpdated = pb.hasUpdated_p
    }
}
