//
//  SubscribeResponse.swift
//  LarkMeegoPush
//
//  Created by ByteDance on 2022/7/13.
//

import Foundation
import LarkMeegoNetClient

public struct SubscribeResponse: Codable {
    public let ssbIds: [String: Int]?
    public let topicSeqIdsMap: [String: TopicSeqIdsModel]?

    private enum CodingKeys: String, CodingKey {
        case ssbIds = "ssb_ids"
        case topicSeqIdsMap = "topic_sequence_ids"
    }
}

public struct TopicSeqIdsModel: Codable {
    public let seqId: Int
    public let updateTime: Int

    private enum CodingKeys: String, CodingKey {
        case seqId = "seq_id"
        case updateTime = "update_time"
    }
}
