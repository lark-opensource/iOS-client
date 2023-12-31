//
//  PlaneTracker.swift
//  ByteView
//
//  Created by chentao on 2020/10/10.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker
import ByteViewNetwork

final class PlaneTracker: TrackHandler {
    let userId: String
    init(userId: String) {
        self.userId = userId
    }

    func track(event: TrackEvent) {
        HttpClient(userId: userId).send(EntrustServerTrackRequest(key: event.name, params: event.params.rawValue)) { result in
            if let error = result.error {
                Logger.tracker.error("upload event:\(event.name) to plane error, backup to tea", error: error)
                VCTracker.post(event, platforms: [.tea])
            }
        }
    }
}
