//
//  TrackDependency.swift
//  AudioSessionScenario
//
//  Created by fakegourmet on 2022/2/21.
//

import Foundation
import AVFoundation

/// Business track dependency
public protocol TrackDependency: AnyObject {
    func trackEvent(event: String, params: [AnyHashable: Any])
}

public extension LarkAudioSession {
    static func setupTrackDependency(_ tracker: TrackDependency) {
        Self.trackers.removeAll { $0.value as? TrackDependency == nil }
        Self.trackers.append(WeakRef(tracker))
    }
}

extension AudioTracker {
    @objc dynamic func trackAudioBusinessEvent(event: String, params: [AnyHashable: Any]) {
        LarkAudioSession.trackers.compactMap { $0.value as? TrackDependency }.forEach {
            $0?.trackEvent(event: event, params: params)
        }
    }
}

fileprivate extension LarkAudioSession {
    static var trackers: [WeakRef<AnyObject>] = []
}
