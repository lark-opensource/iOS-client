//
//  PullVcStaticResourceRequest.swift
//  ByteViewNetwork
//
//  Created by bytedance on 2022/10/30.
//

import Foundation
import RustPB

/// 获取VC 静态资源（缓存）
/// pullVcStaticResource // = 800106
/// Videoconference_V1_PullVcStaticResourceRequest
public struct PullVcStaticResourceRequest {
    public static let command: NetworkCommand = .rust(.pullVcStaticResource)
    public typealias Response = PullVcStaticResourceResponse

    public init(downloadURL: String, resourceName: String, version: Int64) {
        self.downloadURL = downloadURL
        self.resourceName = resourceName
        self.version = version
    }
    public var downloadURL: String
    public var resourceName: String
    public var version: Int64
}

/// Videoconference_V1_PullVcStaticResourceResponse
public struct PullVcStaticResourceResponse {
    public var localPath: String
}

extension PullVcStaticResourceRequest: CustomStringConvertible {
    public var description: String {
        return String(indent: "PullVcStaticResourceRequest",
                      "download: \(downloadURL.hash)",
                      "resourceName: \(resourceName)",
                      "version: \(version)"
                      )
    }
}

extension PullVcStaticResourceResponse: CustomStringConvertible {
    public var description: String {
        return String(indent: "PullVcStaticResourceResponse",
                      "localPath: \(localPath.hash)"
                      )
    }
}

extension PullVcStaticResourceRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_PullVcStaticResourceRequest
    func toProtobuf() throws -> Videoconference_V1_PullVcStaticResourceRequest {
        var request = ProtobufType()
        request.downloadURL = downloadURL
        request.resourceName = resourceName
        request.version = version
        return request
    }
}

extension PullVcStaticResourceResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_PullVcStaticResourceResponse
    init(pb: Videoconference_V1_PullVcStaticResourceResponse) throws {
        self.localPath = pb.localPath
    }
}
