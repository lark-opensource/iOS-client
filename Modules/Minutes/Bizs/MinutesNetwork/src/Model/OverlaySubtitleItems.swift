//
//  OverlaySubtitleItems.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/2/4.
//

import Foundation

public struct OverlaySubtitleItem: Codable, Equatable {

    public let startTime: Int
    public let stopTime: Int
    public let content: String

    private enum CodingKeys: String, CodingKey {
        case startTime = "start_ms"
        case stopTime = "stop_ms"
        case content = "content"
    }
}
