//
//  SlardarTracker.swift
//  AudioSessionScenario
//
//  Created by fakegourmet on 2020/12/17.
//

import Foundation
import LKCommonsTracker

extension AudioTracker {
    private static let slardarEventName = "vc_appreciable_error"

    @objc dynamic func trackAudioEvent(event: String, params: [AnyHashable: Any]) {
        var mergedParams = params
        mergedParams["event"] = event
        let event = SlardarEvent(name: Self.slardarEventName,
                                 metric: [:],
                                 category: [:],
                                 extra: mergedParams)
        Tracker.post(event)
    }
}
