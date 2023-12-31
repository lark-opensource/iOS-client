//
//  MagicShareInfoRequest.swift
//  ByteViewNetwork
//
//  Created by 陈乐辉 on 2022/9/16.
//

import Foundation
import ServerPB

/// 上报共享文档操作信息
/// ServerPB_Ai_magic_share_info_MagicShareInfoRequest
public struct MagicShareInfoRequest {
    public static let command: NetworkCommand = .server(.postMagicShareInfo)
    public typealias Response = MagicShareInfoResponse

    public init(eventType: Int, meetingId: String, objToken: String, timestamp: Int64, shareId: String, info: String?) {
        self.eventType = eventType
        self.meetingId = meetingId
        self.objToken = objToken
        self.timestamp = timestamp
        self.shareId = shareId
        self.info = info
    }

    public var eventType: Int
    public var meetingId: String
    public var objToken: String
    public var timestamp: Int64
    public var shareId: String
    public var info: String?
}

extension MagicShareInfoRequest: CustomStringConvertible {
    public var description: String {
        String(indent: "MagicShareInfoRequest",
               "eventType: \(eventType)",
               "meetingId: \(meetingId)",
               "timestamp: \(timestamp)",
               "objToken.isEmpty: \(objToken.isEmpty)")
    }
}

extension MagicShareInfoRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Ai_magic_share_info_MagicShareInfoRequest

    func toProtobuf() throws -> ServerPB_Ai_magic_share_info_MagicShareInfoRequest {
        var request = ProtobufType()
        request.eventType = .init(rawValue: eventType) ?? .unknown
        request.meetingID = meetingId
        request.objToken = objToken
        request.timestamp = timestamp
        request.shareID = shareId
        request.info = info ?? ""
        return request
    }
}


/// ServerPB_Ai_magic_share_info_MagicShareInfoResponse
public struct MagicShareInfoResponse {
    public var success: Bool
    public var errMsg: String
}

extension MagicShareInfoResponse: RustResponse {
    typealias ProtobufType = ServerPB_Ai_magic_share_info_MagicShareInfoResponse
    init(pb: ServerPB_Ai_magic_share_info_MagicShareInfoResponse) throws {
        self.success = pb.success
        self.errMsg = pb.errMsg
    }
}
