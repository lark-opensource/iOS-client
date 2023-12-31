//
//  ActiveSpeakerConfig.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/10.
//

import Foundation

// disable-lint: magic number
public struct ActiveSpeakerConfig: Decodable {
    public let tickTime: UInt
    /// SDK回调声音的时间间隔 ms
    public let sampleInterval: UInt
    public let maxRecordTime: UInt
    public let minSpeakerVolume: Int
    public let timeBase: Float
    public let rankBase: Float
    public let reportInterval: UInt
    public let tickTimeMill: UInt
    public let holdTimeMs: UInt

    static let `default` = ActiveSpeakerConfig(tickTime: 1, sampleInterval: 200, maxRecordTime: 120, minSpeakerVolume: -38,
                                               timeBase: 2, rankBase: 12, reportInterval: 1000, tickTimeMill: 1000, holdTimeMs: 2500)

    public var indicationDistance: UInt {
        tickTime > 0 ? tickTime * 1000 : 2000
    }

    public var indicationSmooth: UInt {
        sampleInterval > 0 ? sampleInterval : 200
    }
}
