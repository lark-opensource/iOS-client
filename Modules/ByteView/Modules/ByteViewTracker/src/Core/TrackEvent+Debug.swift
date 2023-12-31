//
//  TrackEvent+Debug.swift
//  ByteViewTracker
//
//  Created by kiri on 2022/1/12.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon

extension Logger {
    internal static let dev = Logger.getLogger("Dev")
}

extension TrackEvent {
    func log(originParams: TrackParams, platforms: [TrackPlatform], file: String = #fileID, function: String = #function, line: Int = #line) {
        if self.name == "vc_monitor_core_log" || self.name == "vc_inmeet_perf_monitor" {
            return
        }
        var envId: String?
        var params = originParams.rawValue
        var s = ""
        if let id = self.params[.env_id] as? String, !id.isEmpty {
            params.removeValue(forKey: "env_id")
            envId = id
        }
        let isDevEvent = (self.name == "vc_client_event_dev")
        var actionType = ""
        if isDevEvent {
            if let t = params.removeValue(forKey: "action_type") as? String {
                actionType = t
                s.append("[\(t)]")
            }
            ["scene", "subscene"].forEach { key in
                if let value = params.removeValue(forKey: key) as? String {
                    s.append(value.split(separator: ",").map({ "[\($0)]" }).joined())
                }
            }
            s.append(" ")
        } else {
            s.append("[\(platforms.map({ $0.description }).joined(separator: "|"))]\(self.abTest ? "[ab]" : "")[\(self.name)] ")
        }

        ["event", "action_name"].forEach { key in
            if let value = params.removeValue(forKey: key) {
                s.append("\(value), ")
            }
        }
        let keys = ["duration", "latency", "elapse", "click", "from_source", "target", "code", "error_code", "error_msg", "command"]
        keys.forEach { key in
            if let value = params.removeValue(forKey: key) {
                s.append("\(key): \(value), ")
            }
        }

        if let slardar = self.slardar {
            if !slardar.category.isEmpty {
                s.append("category: \(slardar.category), ")
            }
            if self.name != "vc_basic_performance", !slardar.metric.isEmpty {
                s.append("metric: \(slardar.metric), ")
            }
        }

        if !params.isEmpty {
            s.append("params: \(params)")
        }
        if s.hasSuffix(", ") {
            s.removeLast(2)
        }
        let logger: Logger = isDevEvent ? Logger.dev.withEnv(envId) : Logger.tracker.withEnv(envId)
        if actionType == "warn" {
            logger.warn(s, file: file, function: function, line: line)
        } else {
            logger.info(s, file: file, function: function, line: line)
        }
    }
}
