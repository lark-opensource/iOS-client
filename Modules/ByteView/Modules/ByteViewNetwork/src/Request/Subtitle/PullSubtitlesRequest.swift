//
//  PullSubtitlesRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// Videoconference_V1_PullSubtitlesRequest
public struct PullSubtitlesRequest {
    public static let command: NetworkCommand = .rust(.pullSubtitles)
    public typealias Response = PullSubtitlesResponse

    public init(meetingId: String, breakoutRoomId: String?, count: Int?, targetSegId: Int?, forwardBufferCount: Int?, backwardBufferCount: Int?, isForward: Bool) {
        self.meetingId = meetingId
        self.breakoutRoomId = breakoutRoomId
        self.count = count
        self.targetSegId = targetSegId
        self.forwardBufferCount = forwardBufferCount
        self.backwardBufferCount = backwardBufferCount
        self.isForward = isForward
    }

    public var meetingId: String

    ///分组信息
    public var breakoutRoomId: String?

    public var count: Int?

    /// 起始字幕ID，返回结果包含此ID，不给默认为最早
    public var targetSegId: Int?

    /// 向前 buffer 条数
    public var forwardBufferCount: Int?

    /// 向后 buffer 条数
    public var backwardBufferCount: Int?

    /// 是/否 拉取比target_seg_id更早的字幕
    public var isForward: Bool
}

/// 返回结果按照时间顺序从小到达排列
/// - Videoconference_V1_PullSubtitlesResponse
public struct PullSubtitlesResponse {
    public init(subtitles: [MeetingSubtitleData], nextTargetSegID: Int64, hasMore: Bool) {
        self.subtitles = subtitles
        self.nextTargetSegID = nextTargetSegID
        self.hasMore = hasMore
    }

    public var subtitles: [MeetingSubtitleData]

    public var nextTargetSegID: Int64

    public var hasMore: Bool
}

extension PullSubtitlesRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_PullSubtitlesRequest
    func toProtobuf() throws -> Videoconference_V1_PullSubtitlesRequest {
        var request = ProtobufType()
        request.language = ""
        request.meetingID = meetingId
        if let count = count {
            request.count = Int64(count)
        }
        if let targetSegId = targetSegId {
            request.targetSegID = Int64(targetSegId)
        }
        request.isForward = isForward
        if let forwardBufferCount = forwardBufferCount {
            request.forwardBufferCount = Int32(forwardBufferCount)
        }
        if let backwardBufferCount = backwardBufferCount {
            request.backwardBufferCount = Int32(backwardBufferCount)
        }
        if let breakoutRoomId = breakoutRoomId {
            request.breakoutRoomID = breakoutRoomId
        }
        return request
    }
}

extension PullSubtitlesResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_PullSubtitlesResponse
    init(pb: Videoconference_V1_PullSubtitlesResponse) throws {
        self.nextTargetSegID = pb.nextTargetSegID
        self.hasMore = pb.hasMore_p
        self.subtitles = pb.subtitles.map({ $0.vcType })
    }
}
