//
//  AudioAppreciableTracker.swift
//  ByteViewTracker
//
//  Created by fakegourmet on 2022/11/29.
//

import Foundation
import ByteViewCommon

/// 音频错误可感知耗时，一级分类为 `vc_appreciable_error`
public final class AudioAppreciableTracker {

    private let queue = DispatchQueue(label: "ByteViewCommon.AudioAppreciableTracker")
    private var performanceCache: [DevTrackEvent.Audio: TrackElement] = [:]

    public init() {}

    public func start(_ event: DevTrackEvent.Audio, params: [String: Any] = [:], startTime: CFTimeInterval = CACurrentMediaTime(), interval: DispatchTimeInterval = .seconds(10)) {
        queue.async { [weak self] in
            self?.performanceCache[event] = TrackElement(startTime: startTime, params: params)
            self?.queue.asyncAfter(deadline: .now() + interval) {
                if let self = self, self.performanceCache[event] != nil {
                    self.end(event, params: params)
                }
            }
        }
    }

    public func end(_ event: DevTrackEvent.Audio, params: [String: Any] = [:], endTime: CFTimeInterval = CACurrentMediaTime()) {
        queue.async { [weak self] in
            guard var element = self?.performanceCache.removeValue(forKey: event) else { return }
            element.endTime = endTime
            var finalParams = element.params
            finalParams.merge(params, uniquingKeysWith: { $1 })
            finalParams["duration"] = element.duration
            finalParams["applicationState"] = AppInfo.shared.applicationState.rawValue
            self?.track(event: event, params: finalParams)
        }
    }

    public func cancel(_ event: DevTrackEvent.Audio) {
        queue.async { [weak self] in
            self?.performanceCache.removeValue(forKey: event)
        }
    }

    @inline(__always)
    private func track(event: DevTrackEvent.Audio, params: [String: Any]) {
        DevTracker.post(.audio(event).params(TrackParams(params)))
    }

    private struct TrackElement {
        let startTime: CFTimeInterval
        var endTime: CFTimeInterval = 0
        var params: [String: Any] = [:]
        init(startTime: CFTimeInterval, endTime: CFTimeInterval = 0, params: [String: Any]) {
            self.startTime = startTime
            self.endTime = endTime
            self.params = params
        }

        var duration: Int64 {
            return Int64((endTime - startTime) * 1000)
        }
    }
}
