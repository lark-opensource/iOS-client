//
//  SetVcImChatBannerCloseRequest.swift
//  ByteViewNetwork
//
//  Created by lutingting on 2023/3/27.
//

import Foundation
import RustPB

/// Videoconference_V1_SetVcImChatBannerCloseRequest
/// SET_VC_IM_CHAT_BANNER_CLOSE = 89222  关闭置顶Banner
public struct SetVcImChatBannerCloseRequest {
    public static let command: NetworkCommand = .rust(.setVcImChatBannerClose)

    public let meetingIds: [String]

    public init(meetingIds: [String]) {
        self.meetingIds = meetingIds
    }
}

extension SetVcImChatBannerCloseRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_SetVcImChatBannerCloseRequest
    func toProtobuf() throws -> Videoconference_V1_SetVcImChatBannerCloseRequest {
        var request = ProtobufType()
        request.meetingIds = meetingIds
        return request
    }
}
