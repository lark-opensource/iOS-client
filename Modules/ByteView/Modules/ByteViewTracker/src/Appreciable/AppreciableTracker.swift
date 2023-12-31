//
//  AppreciableTracker.swift
//  ByteView
//
//  Created by chentao on 2021/3/4.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon

public final class AppreciableTracker {
    public static let shared = AppreciableTracker()

    private let queue = DispatchQueue(label: "ByteViewCommon.AppreciableTracker")
    private var performanceCache: [AppreciableEvent: TrackElement] = [:]

    private init() { }

    public func start(_ event: AppreciableEvent, params: [String: Any] = [:], startTime: CFTimeInterval = CACurrentMediaTime()) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.performanceCache[event] = TrackElement(startTime: startTime, params: params)
        }
    }

    public func end(_ event: AppreciableEvent, params: [String: Any] = [:], endTime: CFTimeInterval = CACurrentMediaTime()) {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard var element = self.performanceCache.removeValue(forKey: event) else { return }
            element.endTime = endTime
            var finalParams = element.params
            finalParams.merge(params, uniquingKeysWith: { $1 })
            finalParams["duration"] = element.duration
            let metric: [String: Any] = [event.rawValue: element.duration]
            self.track(type: .vc_basic_performance, event: event.rawValue, params: finalParams, metric: metric)
        }
    }

    public func cancel(_ event: AppreciableEvent) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.performanceCache.removeValue(forKey: event)
        }
    }

    public func track(_ event: AppreciableEvent, params: [String: Any] = [:], type: AppreciableType = .vc_basic_performance, platforms: [TrackPlatform] = [.slardar]) {
        queue.async { [weak self] in
            self?.track(type: type, event: event.rawValue, params: params, abTest: false, platforms: platforms)
        }
    }

    public func trackAB(_ event: AppreciableEvent, params: [String: Any] = [:], type: AppreciableType = .vc_basic_performance) {
        queue.async { [weak self] in
            self?.track(type: type, event: event.rawValue, params: params, abTest: true)
        }
    }

    public func trackError(_ event: AppreciableError, params: [String: Any] = [:]) {
        queue.async { [weak self] in
            self?.track(type: .vc_appreciable_error, event: event.rawValue, params: params)
        }
    }

    @inline(__always)
    private func track(type: AppreciableType, event: String, params: [String: Any], abTest: Bool = false,
                       metric: [String: Any] = [:], category: [String: Any] = [:], platforms: [TrackPlatform] = [.slardar]) {
        var finalParams = params
        finalParams["event"] = event
        var trackEvent = TrackEvent.raw(name: type.rawValue, params: finalParams, abTest: abTest)
        if !metric.isEmpty || !category.isEmpty {
            trackEvent.slardar = .init(metric: metric, category: category)
        }
        VCTracker.shared.track(event: trackEvent, for: platforms)
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
