//
//  SearchSubtitlesResponse.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// Videoconference_V1_SearchSubtitlesRequest
public struct SearchSubtitlesRequest {
    public static let command: NetworkCommand = .rust(.searchSubtitles)
    public typealias Response = SearchSubtitlesResponse

    public init(pattern: String, startSegId: Int?, includeAnnotation: Bool, breakoutRoomId: String?) {
        self.pattern = pattern
        self.startSegId = startSegId
        self.includeAnnotation = includeAnnotation
        self.breakoutRoomId = breakoutRoomId
    }

    /// 要搜索的词
    public var pattern: String

    /// 从哪个 id 开始，往后搜索，不给默认最早
    public var startSegId: Int?

    ///  是否包含注释
    public var includeAnnotation: Bool

    public var breakoutRoomId: String?
}

/// 返回结果按照 seg_id 从小到达排列
/// - Videoconference_V1_SearchSubtitlesResponse
public struct SearchSubtitlesResponse {

    public var matches: [SubtitleSearchMatch]

    public var pattern: String

    public var hasMore: Bool

    public var breakoutRoomId: String
}

/// - 搜索字幕的数据结构
/// - 匹配字幕的 seg_id，和 match 的起始，方便客户端高亮
public struct SubtitleSearchMatch: Equatable {
    public let segId: Int
    public let startPos: [Int]
    public let batchId: Int64
}

extension SearchSubtitlesRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_SearchSubtitlesRequest
    func toProtobuf() throws -> Videoconference_V1_SearchSubtitlesRequest {
        var request = ProtobufType()
        if let startSegId = startSegId {
            request.startSegID = Int64(startSegId)
        }
        request.pattern = pattern
        request.includeAnnotation = includeAnnotation
        if let id = RequestUtil.normalizedBreakoutRoomId(breakoutRoomId) {
            request.breakoutRoomID = id
        }
        return request
    }
}

extension SearchSubtitlesResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_SearchSubtitlesResponse
    init(pb: Videoconference_V1_SearchSubtitlesResponse) throws {
        self.pattern = pb.pattern
        self.hasMore = pb.hasMore_p
        self.breakoutRoomId = pb.breakoutRoomID
        self.matches = pb.matches.map({ m in
            SubtitleSearchMatch(segId: Int(m.segID), startPos: m.startPos.map({ Int($0) }), batchId: 0)
        })
    }
}
