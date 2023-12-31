//
//  GetVcImChatBannerRequest.swift
//  ByteViewNetwork
//
//  Created by lutingting on 2023/3/27.
//

import Foundation
import RustPB

/// GET_VC_IM_CHAT_BANNER = 89221  获取会议事件卡片信息（原始用途：聊天置顶会议banner信息）
/// Videoconference_V1_GetVcImChatBannerRequest
public struct GetVcImChatBannerRequest {
    public static let command: NetworkCommand = .rust(.getVcImChatBanner)
    public typealias Response = GetVcImChatBannerResponse

    public init() {}
}

/// PUSH_VC_IM_CHAT_BANNER_CHANGE = 89223
public struct GetVcImChatBannerResponse {
    public var infos: [IMNoticeInfo]
}


extension GetVcImChatBannerRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_GetVcImChatBannerRequest
    func toProtobuf() throws -> Videoconference_V1_GetVcImChatBannerRequest {
        var request = ProtobufType()
        return request
    }
}

extension GetVcImChatBannerResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_GetVcImChatBannerResponse

    init(pb: Videoconference_V1_GetVcImChatBannerResponse) {
        self.infos = pb.infos.map({ $0.vcType })
    }
}
