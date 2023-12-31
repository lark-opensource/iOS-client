//
//  Summaries.swift
//  MinutesFoundation
//
//  Created by Todd Cheng on 2021/5/12.
//

import Foundation

public enum NewSummaryStatus: Int, Codable {
    case complete = 0
    case generating = 2
    case notReady = 3
    case notSupport = 4
}


public struct SpeakersSummaries: Codable {
    public let aiSpeakerSummary: SummaryContent?

    private enum CodingKeys: String, CodingKey {
        case aiSpeakerSummary = "ai_speaker_summary"
    }

    public struct SummaryContent: Codable {
        public let summaryStatus: NewSummaryStatus
        public let details: [String: Detail]

        public struct Detail: Codable {
            public let content: String
            public let edited: Bool
        }

        private enum CodingKeys: String, CodingKey {
            case summaryStatus = "summary_status"
            case details = "details"
        }
    }
}





public struct Summaries: Codable {
    public let summaryStatus: NewSummaryStatus
    public let isAutoGen: Bool
    public let total: Int
    public let translateLang: String
    public let sectionList: [SectionList]?
    public let contentList: [String: SummaryContentList]?

    private enum CodingKeys: String, CodingKey {
        case summaryStatus = "summary_status"
        case isAutoGen = "is_auto_gen"
        case total = "total"
        case translateLang = "translate_lang"
        case sectionList = "section_list"
        case contentList = "summaries"
    }
}

public enum SummaryContentType: Int, Codable, ModelEnum {
    public static var fallbackValue: SummaryContentType = .unknown

    case text = 0
    case checkbox = 1
    case subsection = 2
    case unknown = -999
}

public struct SectionList: Codable {
    public let title: String
    public let sectionId: Int
    public let contentType: SummaryContentType
    public let contentIds: [String]?
    public let subsectionList: [SectionItem]?

    private enum CodingKeys: String, CodingKey {
        case title = "title"
        case sectionId = "section_id"
        case contentType = "content_type"
        case contentIds = "content_ids"
        case subsectionList = "subsection_list"
    }
}

public struct SectionItem: Codable {
    public let title: String
    public let sectionId: Int
    public let contentType: SummaryContentType
    public let contentIds: [String]?

    private enum CodingKeys: String, CodingKey {
        case title = "title"
        case sectionId = "section_id"
        case contentType = "content_type"
        case contentIds = "content_ids"
    }
}

public struct SummaryContentList: Codable {
    public let contentId: String
    public let startTime: Int
    public let stopTime: Int
    public let sectionId: Int
    public let contentType: SummaryContentType
    public let checked: Bool
    public let sids: [String]?
    public let data: String
    public let title: String

    private enum CodingKeys: String, CodingKey {
        case contentId = "content_id"
        case startTime = "start_time"
        case stopTime = "stop_time"
        case sectionId = "section_id"
        case contentType = "content_type"
        case checked = "checked"
        case sids = "sids"
        case data = "data"
        case title = "title"
    }
}
