//
//  ReactionInfo.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/2/25.
//

import Foundation

public struct ReactionInfo: Codable {
    public init(type: Int, emojiCode: String?, count: Int?, startTime: Int?) {
        self.type = type
        self.emojiCode = emojiCode
        self.count = count
        self.startTime = startTime
        self.uuid = UUID().uuidString
    }

    public let type: Int
    public let emojiCode: String?
    public let count: Int?
    public let startTime: Int?
    public let uuid: String?

    private enum CodingKeys: String, CodingKey {
        case type
        case emojiCode = "emoji_code"
        case count = "emoji_count"
        case startTime = "start_time"
        case uuid = "uuid"
    }
}
