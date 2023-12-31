//
//  VCManageApplyResponse.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// 新增审核申请接口，补齐之前审核相关接口的缺失
/// - ServerPB_Videochat_VCManageApplyRequest
public struct VCManageApplyRequest {
    public static let command: NetworkCommand = .server(.vcManageApply)
    public typealias Response = VCManageApplyResponse

    public init(meetingId: String, breakoutRoomId: String, applyType: ApplyType) {
        self.meetingId = meetingId
        self.breakoutRoomId = breakoutRoomId
        self.applyType = applyType
    }

    public var meetingId: String

    public var breakoutRoomId: String

    public var applyType: ApplyType

    public enum ApplyType: Int, Hashable {
        case applyForHelpFromBreakoutRoom = 1
    }
}

/// ServerPB_Videochat_VCManageApplyResponse
public struct VCManageApplyResponse {

    public var result: VCManageApplyResponse.Result

    public enum Result: Int, Equatable {
        case fail // = 0
        case success // = 1
        case hostBusy // = 2
    }
}

extension VCManageApplyRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_VCManageApplyRequest
    func toProtobuf() throws -> ServerPB_Videochat_VCManageApplyRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.breakoutRoomID = breakoutRoomId
        request.applyType = .init(rawValue: applyType.rawValue) ?? .unknown
        return request
    }
}

extension VCManageApplyResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_VCManageApplyResponse
    init(pb: ServerPB_Videochat_VCManageApplyResponse) throws {
        self.result = .init(rawValue: pb.result.rawValue) ?? .fail
    }
}
