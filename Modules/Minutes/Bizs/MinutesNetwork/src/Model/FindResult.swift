//
//  FindResult.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/13.
//

import Foundation

public enum FindType: Int, Codable, ModelEnum {
    public static var fallbackValue: FindType = .unknown

    case normal = 0
    case keyword = 1
    case unknown = -999
}

public struct FindResultContent: Codable {
    public let subtitles: [String: ParagraphFindResult]
}

public struct Timeline: Codable {
    public let pid: String
    public let sid: String
    public let startTime: String

    private enum CodingKeys: String, CodingKey {
        case pid
        case sid
        case startTime = "start_time"
    }
}

public struct FindResult: Codable {
    public let query: String
    public let type: FindType
    public let content: FindResultContent
    public let timeline: [Timeline]

    private enum CodingKeys: String, CodingKey {
        case query = "query"
        case type = "type"
        case content = "results"
        case timeline = "timeline"
    }
}
