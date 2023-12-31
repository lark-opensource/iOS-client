//
//  GetAvatarPathRequest.swift
//  ByteViewNetwork
//
//  Created by shin on 2023/2/17.
//

import Foundation
import RustPB

public struct GetAvatarPathRequest {
    public static let command: NetworkCommand = .rust(.getAvatarPath)
    public typealias Response = GetAvatarPathResponse

    public init(key: String, entityID: String? = nil, dpSize: Int32, format: String? = "jpg", dpr: Float? = 3.0) {
        self.key = key
        self.entityID = entityID
        self.dpSize = dpSize
        self.format = format
        self.dpr = dpr
    }

    /// 必填，图片唯一的 key
    public var key: String
    public var entityID: String?
    public var dpSize: Int32
    /// 图片格式，默认 jpg
    public var format: String?
    /// https://www.jianshu.com/p/ac9c1c7957ab，默认 3.0
    public var dpr: Float?
}

public struct GetAvatarPathResponse {
    /// 头像 path
    public var path: String
}

extension GetAvatarPathRequest: RustRequestWithResponse {
    typealias ProtobufType = Media_V1_GetAvatarPathRequest
    func toProtobuf() throws -> Media_V1_GetAvatarPathRequest {
        var request = ProtobufType()
        request.key = key
        request.dpSize = dpSize
        request.dpr = dpr ?? 3.0
        request.format = format ?? "png"
        if entityID != nil {
            request.entityID = entityID!
        }
        return request
    }
}

extension GetAvatarPathResponse: RustResponse {
    typealias ProtobufType = Media_V1_GetAvatarPathResponse
    init(pb: Media_V1_GetAvatarPathResponse) throws {
        self.path = pb.path
    }
}
