//
//  Content.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/12.
//

import Foundation

public struct Content: Codable {
    public init(id: String, language: String, startTime: String, stopTime: String, content: String) {
        self.id = id
        self.language = language
        self.startTime = startTime
        self.stopTime = stopTime
        self.content = content
    }

    public let id: String
    public let language: String
    public let startTime: String
    public let stopTime: String
    public let content: String

    private enum CodingKeys: String, CodingKey {
        case id = "cid"
        case language = "language"
        case startTime = "start_time"
        case stopTime = "stop_time"
        case content = "content"
    }
}
