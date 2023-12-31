//
//  ParagraphID.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/12.
//

import Foundation

public struct ParagraphID: Codable {
    public let id: String
    public let startTime: String
    public let stopTime: String

    private enum CodingKeys: String, CodingKey {
        case id = "pid"
        case startTime = "start_time"
        case stopTime = "stop_time"
    }
}
