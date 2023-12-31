//
//  CallKitTracks.swift
//  ByteView
//
//  Created by kiri on 2020/10/21.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker
import ByteViewNetwork

final class CallKitTracks {
    static func trackSetMute(_ muted: Bool, meetType: MeetingType?) {
        guard let trackName = meetType?.trackName else {
            return
        }
        VCTracker.post(name: trackName, params: [.from_source: "call_kit", .action_name: ["mute": (muted ? 1 : 0)]])
    }

    static func trackVideo(meetType: MeetingType) {
        VCTracker.post(name: meetType.trackName, params: [.from_source: "call_kit", .action_name: "video"])
    }
}
