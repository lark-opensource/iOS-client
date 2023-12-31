//
//  BVTracker.swift
//  ByteView
//
//  Created by liurundong.henry on 2021/6/2.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon

public protocol TrackHandler {
    func track(event: TrackEvent)
}

public final class VCTracker {
    public static let shared = VCTracker()

    public func setup(for platform: TrackPlatform, factory: (() -> TrackHandler)?) {
        platform.setFactory(factory)
    }

    /// use `static func post()` for public
    internal func track(event: TrackEvent, for platforms: [TrackPlatform],
                        file: String = #fileID, function: String = #function, line: Int = #line) {
        if event.name.isEmpty || event.name == "none" {
            Logger.tracker.error("event name is invalid: \(event.name), skip track", file: file, function: function, line: line)
            return
        }
        Queue.tracker.async { [weak self] in
            guard let self = self else { return }
            self.trackDirectly(event: event, for: platforms, fillCommonParams: true, file: file, function: function, line: line)
        }
    }

    internal func trackDirectly(event: TrackEvent, for platforms: [TrackPlatform], fillCommonParams: Bool,
                                file: String, function: String, line: Int) {
        let originParams = event.params
        var trackEvent = event
        if fillCommonParams {
            TrackCommonParams.fill(event: &trackEvent)
        }
        trackEvent.log(originParams: originParams, platforms: platforms, file: file, function: function, line: line)
        platforms.forEach { p in
            if let handler = p.factory?() {
                handler.track(event: trackEvent)
            } else {
                Logger.tracker.error("can't find handler for \(p)")
            }
        }
    }
}

public extension VCTracker {
    static func post(name: TrackEventName, params: TrackParams = [:], time: Date = Date(),
                     platforms: [TrackPlatform] = [.tea],
                     file: String = #fileID, function: String = #function, line: Int = #line) {
        shared.track(event: TrackEvent(name: name, params: params, trackTime: time), for: platforms,
                     file: file, function: function, line: line)
    }

    static func post(_ event: TrackEvent, platforms: [TrackPlatform] = [.tea],
                     file: String = #fileID, function: String = #function, line: Int = #line) {
        shared.track(event: event, for: platforms, file: file, function: function, line: line)
    }
}

/// 常用的logger
public extension Logger {
    static let tracker = getLogger("Tracker")

    internal func withEnv(_ envId: String?) -> Logger {
        if let envId = envId, !envId.isEmpty {
            return withContext(envId).withTag("[\(envId)]")
        } else {
            return self
        }
    }
}
