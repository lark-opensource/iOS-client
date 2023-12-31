//
//  SentencesFindResult.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/13.
//

import Foundation

public struct SentencesFindResult: Codable {
    public let id: String
    public let highlight: [Highlight]

    private enum CodingKeys: String, CodingKey {
        case id = "sid"
        case highlight = "highlight"
    }
}
