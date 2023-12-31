//
//  VoteDataModel.swift
//  SKCommon
//
//  Created by zhysan on 2022/9/13.
//

import Foundation

public struct DocVote {
    public struct OptionContext: Codable {
        public let pageId: String
        public let blockId: String
        public let optionId: String
        public let voteCount: Int64?
        public let offset: String?
        public let isVoteDesc: Bool
        
        enum CodingKeys: String, CodingKey {
            case pageId = "page_id"
            case blockId = "block_id"
            case optionId = "option_id"
            case voteCount = "vote_count"
            case offset
            case isVoteDesc
        }
    }
    
    struct OptionData: Codable {
        public let offsetStr: String?
        public let count: Int64
        public let optionId: String?
        public let votes: [VoteMember]
        
        enum CodingKeys: String, CodingKey {
            case offsetStr = "offset_str"
            case count
            case optionId = "option_id"
            case votes
        }
    }

    public struct VoteMember: Codable {
        public let userId: String
        public let emojiId: String?
        public let avatarUrl: String?
        public let userName: String?
        public let voteTime: TimeInterval?
        
        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case emojiId = "emoji_id"
            case avatarUrl = "avatar_url"
            case userName = "user_name"
            case voteTime = "vote_time"
        }
    }
}
