//
//  SilenceInfo.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/4/7.
//

import Foundation

public struct SilenceRange: Codable {
    public let startTime: Int
    public let stopTime: Int

    private enum CodingKeys: String, CodingKey {
        case startTime = "start_time"
        case stopTime = "stop_time"
    }

    public func contains(_ value: Int) -> Bool {
        return value >= startTime && value <= stopTime
    }
}

public struct SilenceInfo: Codable {

    public let toast: String
    public let total: Int
    public let details: [SilenceRange]

    public func nextStopTime(_ value: Int) -> Int? {
        for range in details {
            if range.contains(value) {
                return range.stopTime
            }
        }

        return nil
    }

}
