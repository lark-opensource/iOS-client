//
//  Sentence.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/12.
//

import Foundation

public struct Sentence: Codable {
    public init(id: String, language: String, startTime: String, stopTime: String, contents: [Content], highlight: [Highlight]?) {
        self.id = id
        self.language = language
        self.startTime = startTime
        self.stopTime = stopTime
        self.contents = contents
        self.highlight = highlight
    }

    public let id: String
    public let language: String
    public let startTime: String
    public let stopTime: String
    public let contents: [Content]
    public let highlight: [Highlight]?

    private enum CodingKeys: String, CodingKey {
        case id = "sid"
        case language = "language"
        case startTime = "start_time"
        case stopTime = "stop_time"
        case contents = "contents"
        case highlight = "highlight"
    }
}
