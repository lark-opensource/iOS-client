//
//  TrackEvent.swift
//  ByteView
//
//  Created by kiri on 2020/10/22.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation

public struct TrackEvent {
    public let name: String
    public var params: TrackParams
    public let abTest: Bool
    public let trackTime: Date

    public var slardar: SlardarExtraInfo?

    internal let trackName: TrackEventName

    private init(name: String, params: TrackParams, abTest: Bool, trackTime: Date = Date()) {
        self.name = name
        self.params = params
        self.abTest = abTest
        self.trackTime = trackTime
        self.trackName = TrackEventName(rawValue: name) ?? .unknown
    }

    public init(name: TrackEventName, params: TrackParams = .init(), abTest: Bool = false,
                trackTime: Date = Date()) {
        self.name = name.rawValue
        self.params = params
        self.abTest = abTest
        self.trackTime = trackTime
        self.trackName = name
    }

    public struct SlardarExtraInfo {
        public var metric: [String: Any]
        public var category: [String: Any]

        public init(metric: [String: Any], category: [String: Any]) {
            self.metric = metric
            self.category = category
        }
    }

    /// 仅供动态埋点使用
    /// - parameters:
    ///  - name: Event名称
    ///  - params: 字典里的bool值会自动转为字符串：true/false
    ///  - abTest: 是否使用ABTestTracker
    public static func raw(name: String, params: [String: Any] = [:], abTest: Bool = false) -> TrackEvent {
        TrackEvent(name: name, params: TrackParams(raw: params), abTest: abTest)
    }
}
