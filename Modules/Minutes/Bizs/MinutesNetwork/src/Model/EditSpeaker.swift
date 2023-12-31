//
//  SpeakerSuggestion.swift
//  MinutesFoundation
//
//  Created by chenlehui on 2021/6/20.
//

import Foundation

public struct SpeakerSuggestion: Codable {

    public var total: Int?
    public var offset: Int?
    public var size: Int?
    public var hasMore: Bool?
    public var paragraphNum: Int?
    public var speakerShowName: String?
    public var list: [Participant]?

    private enum CodingKeys: String, CodingKey {
        case total = "total"
        case offset = "offset"
        case size = "size"
        case hasMore = "has_more"
        case list = "list"
        case paragraphNum = "paragraph_num"
        case speakerShowName = "speaker_show_name"
    }
}

public struct SpeakerMarker: Codable, Hashable {

    public var mType: Int?
    public var mUserId: String?
    public var mName: String?

    private enum CodingKeys: String, CodingKey {
        case mType = "m_type"
        case mUserId = "m_user_id"
        case mName = "m_name"
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(mUserId)
    }
}

public struct SpeakerCount: Codable {
    public var count: Int

    private enum CodingKeys: String, CodingKey {
        case count = "count"
    }
}

public struct SpeakerUpdate: Codable {

    public struct Error: Codable {
        public var editorName: String?
        public var denyType: String?

        private enum CodingKeys: String, CodingKey {
            case editorName = "editor_name"
            case denyType = "deny_type"
        }
    }
    public var user: Participant?
    public var error: Error?
    public var clusterAllUpdated: Int? // 1: yes, 0: no

    private enum CodingKeys: String, CodingKey {
        case clusterAllUpdated = "cluster_all_updated"
        case user = "user"
        case error = "error"
    }
}

public struct SpeakerUserChoice: Codable {
    public var batchUpdateStatus: Int?

    private enum CodingKeys: String, CodingKey {
        case batchUpdateStatus = "cluster_batch_update"
    }
}
