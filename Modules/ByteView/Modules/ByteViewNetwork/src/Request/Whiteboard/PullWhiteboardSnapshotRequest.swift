//
//  PullWhiteboardSnapshotRequest.swift
//  ByteViewNetwork
//
//  Created by Prontera on 2022/3/20.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// 拉取白板 snapshot
/// - ServerPB_Videochat_whiteboard_PullWhiteboardSnapshotRequest
public struct PullWhiteboardSnapshotRequest {
    public static let command: NetworkCommand = .server(.pullWhiteboardSnapshot)
    public typealias Response = PullWhiteboardSnapshotResponse

    public init(pageIds: [Int64],
                whiteboardID: Int64) {
        self.pageIds = pageIds
        self.whiteboardID = whiteboardID
    }

    /// 指定拉取page
    public var pageIds: [Int64] = []

    public var whiteboardID: Int64
}

/// - ServerPB_Videochat_whiteboard_PullWhiteboardSnapshotResponse
public struct PullWhiteboardSnapshotResponse {

    public var snapshots: [WhiteboardSnapshot]

}

extension PullWhiteboardSnapshotRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_whiteboard_PullWhiteboardSnapshotRequest
    func toProtobuf() throws -> ServerPB_Videochat_whiteboard_PullWhiteboardSnapshotRequest {
        var request = ProtobufType()
        request.pageIds = pageIds
        request.whiteboardID = whiteboardID
        return request
    }
}

extension PullWhiteboardSnapshotResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_whiteboard_PullWhiteboardSnapshotResponse
    init(pb: ServerPB_Videochat_whiteboard_PullWhiteboardSnapshotResponse) throws {
        self.snapshots = pb.snapshots.map { $0.vcType }
    }
}
