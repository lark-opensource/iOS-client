//
//  SyncSubtitlesRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - Videoconference_V1_SyncSubtitlesRequest
public struct SyncSubtitlesRequest {
    public static let command: NetworkCommand = .rust(.syncSubtitles)
    public typealias Response = SyncSubtitlesResponse

    public init(meetingId: String, breakoutRoomId: String?, forceSync: Bool) {
        self.meetingId = meetingId
        self.forceSync = forceSync
        self.breakoutRoomId = breakoutRoomId
    }

    public var meetingId: String

    ///为 true 时会强制停止正在进行中的同步而开始新的同步，例如切换字幕
    public var forceSync: Bool

    public var breakoutRoomId: String?
}

/// - Videoconference_V1_SyncSubtitlesResponse
public struct SyncSubtitlesResponse {
    public init(meetingId: String, breakoutRoomId: String) {
        self.meetingId = meetingId
        self.breakoutRoomId = breakoutRoomId
    }

    public var meetingId: String

    public var breakoutRoomId: String
}

extension SyncSubtitlesRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_SyncSubtitlesRequest
    func toProtobuf() throws -> Videoconference_V1_SyncSubtitlesRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        if let id = RequestUtil.normalizedBreakoutRoomId(breakoutRoomId) {
            request.breakoutRoomID = id
        }
        request.forceSync = forceSync
        return request
    }
}

extension SyncSubtitlesResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_SyncSubtitlesResponse
    init(pb: Videoconference_V1_SyncSubtitlesResponse) throws {
        self.meetingId = pb.meetingID
        self.breakoutRoomId = pb.breakoutRoomID
    }
}
