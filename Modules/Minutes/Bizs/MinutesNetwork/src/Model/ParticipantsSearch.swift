//
//  ParticipantsSearch.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/12.
//

import Foundation

public struct ParticipantsSearch: Codable {
    public let hasMore: Bool
    public let list: [Participant]?

    private enum CodingKeys: String, CodingKey {
        case hasMore = "has_more"
        case list = "list"
    }
}
