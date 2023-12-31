//
//  GetRtcFeatureGatingRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 根据前缀搜索fg,只开放给移动端
/// - 需求及技术文档：https://bytedance.feishu.cn/docs/doccn8B9XMSLU75mubMe8M3hmUU?sidebarOpen=1
/// - SEARCH_FEATURE_GATING_BY_PREFIX
/// - Settings_V1_SearchFeatureGatingByPrefixRequest
public struct GetRtcFeatureGatingRequest {
    public static let command: NetworkCommand = .rust(.searchFeatureGatingByPrefix)
    public typealias Response = GetRtcFeatureGatingResponse

    public init() {}
}

/// - Settings_V1_SearchFeatureGatingByPrefixResponse
public struct GetRtcFeatureGatingResponse: Codable, Equatable {
    public init() {}
    public var fgJsonString: String?
}

extension GetRtcFeatureGatingRequest: RustRequestWithResponse {
    typealias ProtobufType = Settings_V1_SearchFeatureGatingByPrefixRequest
    func toProtobuf() throws -> Settings_V1_SearchFeatureGatingByPrefixRequest {
        var request = ProtobufType()
        request.fgKeyPrefix = "byteview.callmeeting.client.rtc"
        return request
    }
}

extension GetRtcFeatureGatingResponse: RustResponse {
    typealias ProtobufType = Settings_V1_SearchFeatureGatingByPrefixResponse
    init(pb: Settings_V1_SearchFeatureGatingByPrefixResponse) throws {
        self.fgJsonString = pb.hasFgJsonString ? pb.fgJsonString : nil
    }
}
