//
//  PullMeetingByShareCodeRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - ServerPB_Videochat_PullVideochatByShareCodeRequest
public struct PullMeetingByShareCodeRequest {
    public static let command: NetworkCommand = .server(.pullVideochatByShareCode)
    public typealias Response = PullMeetingByShareCodeResponse

    public init(shareCode: String) {
        self.shareCode = shareCode
    }

    public var shareCode: String
}

/// - ServerPB_Videochat_PullVideochatByShareCodeResponse
public struct PullMeetingByShareCodeResponse {

    public var info: ServerVideoChatInfo
}

/// ServerPB_Videochat_VideoChatInfo
public struct ServerVideoChatInfo {
    public init(id: String, subtype: SubType) {
        self.id = id
        self.subtype = subtype
    }

    public var id: String
    public var subtype: SubType

    public enum SubType: Int, Hashable {
        case `default` // = 0
        case screenShare // = 1
        case wiredScreenShare // = 2
        case followShare // = 3
        case chatRoom // = 4
        case samePageMeeting // = 5
        case enterprisePhoneCall // = 6
    }
}

extension PullMeetingByShareCodeRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_PullVideochatByShareCodeRequest
    func toProtobuf() throws -> ServerPB_Videochat_PullVideochatByShareCodeRequest {
        var request = ProtobufType()
        request.shareCode = shareCode
        return request
    }
}

extension PullMeetingByShareCodeResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_PullVideochatByShareCodeResponse
    init(pb: ServerPB_Videochat_PullVideochatByShareCodeResponse) throws {
        self.info = ServerVideoChatInfo(id: pb.info.id, subtype: .init(rawValue: pb.info.settings.subType.rawValue) ?? .default)
    }
}
