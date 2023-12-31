//
//  ReactionInfoResponse.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/2/25.
//

import Foundation

public struct ReactionInfoResponse: Codable {

    public let timeline: [ReactionInfo]

}

public struct MergedReactionInfoResponse {

    public let reactions: [ReactionInfo]

    enum CodingKeys: String, CodingKey {
        case timeline
    }

    enum TimelineKeys: String, CodingKey {
        case reactions
    }
}

extension MergedReactionInfoResponse: Decodable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let timeline = try values.nestedContainer(keyedBy: TimelineKeys.self, forKey: .timeline)
        reactions = try timeline.decode([ReactionInfo].self, forKey: .reactions)
    }
}

extension MergedReactionInfoResponse: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        var timeline = container.nestedContainer(keyedBy: TimelineKeys.self, forKey: .timeline)
        try timeline.encode(reactions, forKey: .reactions)
    }
}
