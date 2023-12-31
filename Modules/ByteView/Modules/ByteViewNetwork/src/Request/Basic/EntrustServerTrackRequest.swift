//
//  EntrustServerTrackRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// 会议核心埋点
/// - ENTRUST_SERVER_TRACK = 87001
/// - ServerPB_Vcinfo_EntrustServerTrackRequest
public struct EntrustServerTrackRequest {
    public static let command: NetworkCommand = .server(.entrustServerTrack)

    public init(key: String, params: [String: Any], trackType: TrackType? = nil, rtcScreenStreamEvent: RTCScreenStreamingEvent? = nil) {
        self.key = key
        self.params = params
        self.trackType = trackType
        self.rtcScreenStreamEvent = rtcScreenStreamEvent
    }

    public var key: String

    public var params: [String: Any]

    public var trackType: TrackType?

    public var rtcScreenStreamEvent: RTCScreenStreamingEvent?

    public enum TrackType: Int, Hashable {
        case `default` = 0
        case rtcScreenStreaming
    }

    public struct RTCScreenStreamingEvent {
        var eventType: EventType
        var meetingId: String
        var timestamp: Int64

        public init(eventType: EventType, meetingId: String, timestamp: Int64) {
            self.eventType = eventType
            self.meetingId = meetingId
            self.timestamp = timestamp
        }

        public enum EventType: Int, Hashable {
            case startRTCPublish = 1
            case stopRTCPublish
        }
    }
}

extension EntrustServerTrackRequest: RustRequest {
    typealias ProtobufType = ServerPB_Vcinfo_EntrustServerTrackRequest

    func toProtobuf() throws -> ServerPB_Vcinfo_EntrustServerTrackRequest {
        var request = ProtobufType()
        request.key = key
        let data = try JSONSerialization.data(withJSONObject: params)
        if let jsonString = String(data: data, encoding: .utf8) {
            request.jsonParams = jsonString
        }
        if let trackType = trackType {
            request.trackType = ServerPB_Vcinfo_EntrustServerTrackRequest.TrackType(rawValue: trackType.rawValue ) ?? .rtcScreenStreaming
        }
        if let rtcScreenStreamEvent = rtcScreenStreamEvent {
            var pbStreamingEvent = ServerPB_Vcinfo_EntrustServerTrackRequest.RTCScreenStreamingEvent()
            pbStreamingEvent.meetingID = rtcScreenStreamEvent.meetingId
            pbStreamingEvent.timestamp = rtcScreenStreamEvent.timestamp
            pbStreamingEvent.eventType = ServerPB_Vcinfo_EntrustServerTrackRequest.RTCScreenStreamingEvent.EventType(rawValue: rtcScreenStreamEvent.eventType.rawValue) ?? .startRtcPublish
            request.rtcScreenStreamingEvent = pbStreamingEvent
        }
        return request
    }
}
