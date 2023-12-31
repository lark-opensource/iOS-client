//
//  Paragraph.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/12.
//

import Foundation

public enum ParagraphType: Int, Codable, ModelEnum {
    public static var fallbackValue: ParagraphType = .unknown

    case normal
    case reserve1
    case reserve2
    case reserve3
    case reserve4
    case reserve5
    case unknown = -999
}

public struct Paragraph: Codable {

    public init(id: String, startTime: String, stopTime: String, type: ParagraphType?, speaker: Participant?, sentences: [Sentence]) {
        self.id = id
        self.startTime = startTime
        self.stopTime = stopTime
        self.type = type ?? .normal
        self.speaker = speaker
        self.sentences = sentences
    }

    public var id: String
    public var startTime: String
    public var stopTime: String
    public var type: ParagraphType
    public var speaker: Participant?
    public var sentences: [Sentence]
    public var isSkeletonType: Bool = false
    
    private enum CodingKeys: String, CodingKey {
        case id = "pid"
        case startTime = "start_time"
        case stopTime = "stop_time"
        case speaker = "speaker"
        case sentences = "sentences"
        case type = "paragraph_type"
    }
}
