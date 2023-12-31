//
//  Highlight.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/13.
//

import Foundation

public struct Highlight: Codable {

    public let offset: Int
    public let size: Int
    public let type: Int
    public let seq: Int?
    public let uuid: String?
    public let commentID: String?
    public let startTime: Int?
    public let id: String?

    public init(offset: Int, size: Int, type: Int, seq: Int? = nil, uuid: String? = nil, commentID: String? = nil, startTime: Int? = nil, id: String? = nil) {
        self.offset = offset
        self.size = size
        self.type = type
        self.seq = seq
        self.uuid = uuid
        self.commentID = commentID
        self.startTime = startTime
        self.id = id
    }

    private enum CodingKeys: String, CodingKey {
        case offset = "offset"
        case size = "size"
        case type = "type"
        case seq = "seq"
        case uuid = "uuid"
        case startTime = "startTime"
        case commentID = "comment_id"
        case id = "highlight_id"
    }
}
