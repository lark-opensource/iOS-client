//
//  RtcStatus.swift
//  ByteView
//
//  Created by kiri on 2022/10/9.
//

import Foundation

public final class RtcStatus {
    private let sessionId: String
    public init(engine: InMeetRtcEngine) {
        self.sessionId = engine.rtc.sessionId
    }

    public func tryGetAllVideoStreamStatus() -> [StreamStatus] {
        #if RTCBRIDGE_HAS_SDK
        return VideoStreamManager.shared.tryGetAllStreamStatus(sessionId: sessionId)
        #else
        return []
        #endif
    }

    public func tryGetVideoStreamStatus(key: RtcStreamKey) -> StreamStatus? {
        #if RTCBRIDGE_HAS_SDK
        return VideoStreamManager.shared.tryGetStreamStatus(key: key)
        #else
        return nil
        #endif
    }
}
