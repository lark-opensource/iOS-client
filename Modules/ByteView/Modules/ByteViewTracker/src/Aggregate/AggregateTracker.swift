//
//  AggregateTracker.swift
//  ByteViewTracker
//
//  Created by shin on 2023/4/10.
//

import ByteViewCommon
import Foundation

public final class AggregateTracker {
    public static let shared = AggregateTracker()
    private let queue = DispatchQueue(label: "ByteViewCommon.AggregateTracker")

    /// 场景变更事件
    @RwAtomic private var sceneEvents: [AggSceneEvent] = []

    private init() {}

    public static func trackEvent(_ event: AggregateEvent) {
        Self.shared._trackEvent(event)
    }

    private func _trackEvent(_ event: AggregateEvent) {
        queue.async {
            var params = event.params
            let reportTs = TrackCommonParams.clientNtpTime
            let sceneEvents = self.reportSceneEvents(ts: reportTs)
            var aggScenes: [String: AggSceneEventChange] = [:]
            sceneEvents.forEach { event in
                let eventKey = event.scene.aggKey
                var change: AggSceneEventChange
                if let obj = aggScenes[eventKey] {
                    change = obj
                    change.count += event.counter
                    switch event.optMode {
                    case .coexist, .froze:
                        change.duration += event.duration
                    case .count:
                        break
                    }
                    if let value = event.sampleMeta?.value {
                        change.appendValue(value)
                    }
                    if let config = event.sampleMeta?.config, change.config == nil {
                        change.config = config
                    }
                } else {
                    let values: [Float]?
                    let config = event.sampleMeta?.config
                    if let value = event.sampleMeta?.value {
                        values = [value]
                    } else {
                        values = nil
                    }
                    change = AggSceneEventChange(count: event.counter,
                                                 duration: event.duration,
                                                 config: config,
                                                 values: values)
                }
                aggScenes[eventKey] = change
            }
            let aggScenesParam = aggScenes.mapValues({ $0.trackKV })
            params["agg_scenes"] = aggScenesParam
            params["scene_events"] = sceneEvents.map({ $0.trackKV })
            guard let data = try? JSONSerialization.data(withJSONObject: params),
                  let aggEvents = String(data: data, encoding: .utf8)
            else {
                Logger.tracker.error("invalid vc_ios_meeting_aggregate_event, \(event.sampleSeq)")
                return
            }
            let teaParams: TrackParams = ["agg_events": aggEvents]
            let teaEvent = TrackEvent(name: .vc_ios_meeting_aggregate_event, params: teaParams)
            #if DEBUG
            Logger.tracker.info("\(teaEvent)")
            #else
            VCTracker.shared.track(event: teaEvent, for: [.tea])
            #endif
        }
    }
}

/// 增量上报版本
public extension AggregateTracker {

    static func resetSceneEvents() {
        Self.shared._resetSceneEvents()
    }

    /// 场景开始
    /// - Parameter scene: 开始的场景
    ///
    /// 如果场景是互斥的，则会自动结束已存在未冻结的场景，
    /// 场景类型详细参考 scene.optMode
    static func entry(scene: AggSceneEvent.Scene, meta: AggSceneEvent.SampleMeta? = nil) {
        let entryTs = TrackCommonParams.clientNtpTime
        Self.shared._entry(scene: scene, at: entryTs, meta: meta)
    }

    /// 场景结束
    /// - Parameter scene: 结束的场景
    static func leave(scene: AggSceneEvent.Scene) {
        let leaveTs = TrackCommonParams.clientNtpTime
        Self.shared._leave(scene: scene, at: leaveTs)
    }

    /// 同一场景（state 不同）全部结束
    /// - Parameter scene: 结束的场景
    static func leaveAll(scene: AggSceneEvent.Scene) {
        let leaveTs = TrackCommonParams.clientNtpTime
        Self.shared._leaveAll(scene: scene, at: leaveTs)
    }

    private func _resetSceneEvents() {
        queue.async {
            self.sceneEvents.removeAll()
        }
    }

    private func _entry(scene: AggSceneEvent.Scene,
                        at ts: Int64,
                        meta: AggSceneEvent.SampleMeta? = nil)
    {
        queue.async {
            var createInstance = true
            self.sceneEvents = self.sceneEvents.map {
                var event = $0
                if event.scene.eventKey == scene.eventKey {
                    let optMode = event.optMode
                    switch optMode {
                    case .froze:
                        event.froze(at: ts)
                    case .count:
                        createInstance = false
                        event.increase()
                    case .coexist:
                        // 共存情况下，如果进入的场景 state 相同，则先结束上一个，进入下一个
                        if event.scene.aggKey == scene.aggKey {
                            event.froze(at: ts)
                        }
                    }
                }
                return event
            }
            if createInstance {
                let event = AggSceneEvent(scene: scene, entryTs: ts, sampleMeta: meta)
                self.sceneEvents.append(event)
            }
        }
    }

    private func _leave(scene: AggSceneEvent.Scene, at ts: Int64) {
        queue.async {
            self.sceneEvents = self.sceneEvents.map {
                var event = $0
                if event.scene == scene {
                    event.froze(at: ts)
                }
                return event
            }
        }
    }

    private func _leaveAll(scene: AggSceneEvent.Scene, at ts: Int64) {
        queue.async {
            self.sceneEvents = self.sceneEvents.map {
                var event = $0
                if event.scene.eventKey == scene.eventKey {
                    event.froze(at: ts)
                }
                return event
            }
        }
    }

    private func reportSceneEvents(ts: Int64, leave: Bool = false) -> [AggSceneEvent] {
        self.sceneEvents = self.sceneEvents.map {
            var event = $0
            event.update(at: ts)
            return event
        }

        let reportEvents = self.sceneEvents
        if leave {
            self.sceneEvents.removeAll()
        } else {
            self.sceneEvents.removeAll(where: { $0.frozen })
        }
        self.sceneEvents = self.sceneEvents.map {
            var event = $0
            event.reportFinished(at: ts)
            return event
        }
        return reportEvents
    }
}
