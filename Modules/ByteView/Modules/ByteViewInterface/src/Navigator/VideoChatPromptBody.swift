//
//  VideoChatPromptBody.swift
//  ByteViewInterface
//
//  Created by kiri on 2023/6/30.
//

import Foundation

/// Prompt, /client/videochat/prompt
public struct VideoChatPromptBody: CodablePathBody {
    /// /client/videochat/prompt
    public static let path = "/client/videochat/prompt"

    public let id: String
    public let source: Source

    public init(id: String, source: Source) {
        self.id = id
        self.source = source
    }

    public enum Source: String, Codable {
        case calendar // 日程会议入会提醒
    }
}
