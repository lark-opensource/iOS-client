//
//  SentenceHighlightsInfo.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/2/2.
//

import Foundation

public struct SentenceHighlightsInfo: Codable {
    public let id: String
    public let language: String
    public let highlights: [Highlight]?

    public init(id: String, language: String, highlights: [Highlight]?) {
        self.id = id
        self.language = language
        self.highlights = highlights
    }

    private enum CodingKeys: String, CodingKey {
        case id = "sid"
        case language = "language"
        case highlights = "highlights"
    }
}
