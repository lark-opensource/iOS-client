//
//  SearchTranscriptRequest.swift
//  ByteViewNetwork
//
//  Created by 陈乐辉 on 2023/6/21.
//

import Foundation
import RustPB

// SEARCH_TRANSCRIPT = 88024; 搜索转录
public struct SearchTranscriptRequest {
    public static let command: NetworkCommand = .rust(.searchTranscript)
    public typealias Response = SearchTranscriptResponse
    /// 要搜索的词
    public var pattern: String

    /// 从哪个 id 开始，往后搜索，不给默认最早
    public var startSegId: Int?

    public init(pattern: String, startSegId: Int? = nil) {
        self.pattern = pattern
        self.startSegId = startSegId
    }
}

extension SearchTranscriptRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_SearchTranscriptRequest
    func toProtobuf() throws -> Videoconference_V1_SearchTranscriptRequest {
        var request = ProtobufType()
        if let startSegId = startSegId {
            request.startSegID = Int64(startSegId)
        }
        request.pattern = pattern
        return request
    }
}

public struct SearchTranscriptResponse {
    public var matches: [SubtitleSearchMatch]

    public var pattern: String

    public var hasMore: Bool
}

extension SearchTranscriptResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_SearchTranscriptResponse
    init(pb: Videoconference_V1_SearchTranscriptResponse) throws {
        self.pattern = pb.pattern
        self.hasMore = pb.hasMore_p
        self.matches = pb.matches.map({ m in
            SubtitleSearchMatch(segId: Int(m.sentenceID), startPos: m.startPos.map({ Int($0) }), batchId: m.batchID)
        })
    }
}
