//
//  ParagraphFindResult.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/13.
//

import Foundation

public struct ParagraphFindResult: Codable {
    public let id: String
    public let sentences: [SentencesFindResult]

    private enum CodingKeys: String, CodingKey {
        case id = "pid"
        case sentences = "sentences"
    }
}
