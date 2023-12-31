//
//  GetFollowResourcesRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// GET_FOLLOW_RESOURCES
/// - Videoconference_V1_GetFollowResourcesRequest
public struct GetFollowResourcesRequest {
    public static let command: NetworkCommand = .rust(.getFollowResources)
    public typealias Response = GetFollowResourcesResponse

    public init(resources: [String: String]) {
        self.resources = resources
    }

    /// <id, version>
    public var resources: [String: String]
}

/// - Videoconference_V1_GetFollowResourcesResponse
public struct GetFollowResourcesResponse {

    /// 资源列表
    public var resources: [String: FollowResource]
}

extension GetFollowResourcesRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_GetFollowResourcesRequest
    func toProtobuf() throws -> Videoconference_V1_GetFollowResourcesRequest {
        var request = ProtobufType()
        request.resources = resources
        return request
    }
}

extension GetFollowResourcesResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_GetFollowResourcesResponse
    init(pb: Videoconference_V1_GetFollowResourcesResponse) throws {
        self.resources = pb.resources.mapValues({ $0.vcType })
    }
}
