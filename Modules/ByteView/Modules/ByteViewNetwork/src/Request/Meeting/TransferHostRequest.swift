//
//  TransferHostRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - commandID: 89303
/// - CHECK_VC_MANAGE_CAPABILITIES
/// - ServerPB_Videochat_CheckVCManageCapabilitiesRequest
public struct TransferHostRequest {
    public static let command: NetworkCommand = .server(.checkVcManageCapabilities)
    public typealias Response = TransferHostResponse

    public init(meetingId: String, targetUser: ByteviewUser) {
        self.meetingId = meetingId
        self.targetUser = targetUser
    }

    /// meetingID
    public var meetingId: String

    /// 目标主持人
    public var targetUser: ByteviewUser
}

/// Videoconference_V1_CheckVCManageCapabilitiesResponse
public struct TransferHostResponse {

    /// 将失效的会管功能i18nkey 列表
    public var keys: [String]

    public var checkResult: CheckResult

    public enum CheckResult: Int, Hashable {
        case unknown // = 0

        /// 检测通过
        case success // = 1

        /// 需要提醒原主持人
        case neednotice // = 2
    }
}

extension TransferHostRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_CheckVCManageCapabilitiesRequest
    func toProtobuf() throws -> ServerPB_Videochat_CheckVCManageCapabilitiesRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.targetUser = targetUser.serverPbType
        return request
    }
}

extension TransferHostResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_CheckVCManageCapabilitiesResponse
    init(pb: ServerPB_Videochat_CheckVCManageCapabilitiesResponse) throws {
        self.checkResult = .init(rawValue: pb.checkResult.rawValue) ?? .unknown
        self.keys = pb.keys
    }
}
