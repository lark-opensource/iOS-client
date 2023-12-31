//
//  ExtensionTrackPoster.swift
//  LarkExtensionAssembly
//
//  Created by 王元洵 on 2021/3/30.
//

import Foundation
import LKCommonsTracker
import LKCommonsLogging
import LarkExtensionServices

enum ExtensionTrackPoster {

    private static let logger = Logger.log(ExtensionTrackPoster.self, category: "module.extension.track.poster")
    private static var poster: Poster = EventPoster()

    static func post() {
        guard let currentEvents = ExtensionTracker.shared.popEventsForPosting() else {
            Self.logger.info("no extension logs")
            return
        }
        currentEvents.forEach {
            guard let type = $0["type"] as? String else {
                Self.logger.warn("invalid extension log type")
                return
            }
            switch type {
            case "TEA": poster.postTeaEvent($0)
            case "Slardar": poster.postSlardarEvent($0)
            default: assertionFailure("未知的extension埋点类型")
            }
        }
    }
}

/// 仅供测试需要
protocol Poster {
    func postTeaEvent(_ event: [String: Any])
    func postSlardarEvent(_ event: [String: Any])
}

final class EventPoster: Poster {

    private static let logger = Logger.log(EventPoster.self, category: "module.extension.track.poster")

    func postTeaEvent(_ event: [String: Any]) {
        guard let key = event["key"] as? String else {
            Self.logger.warn("invalid extension log key")
            return
        }
        let params = event["params"] as? [String: Any] ?? [:]
        let md5AllowList = event["md5AllowList"] as? [AnyHashable] ?? []
        Self.logger.info("consume extension log, key: \(key), params: \(params)")
        Tracker.post(TeaEvent(key, params: params, md5AllowList: md5AllowList))
    }

    func postSlardarEvent(_ event: [String: Any]) {
        guard let key = event["key"] as? String else { return }
        Tracker.post(SlardarEvent(name: key,
                                  metric: event["metric"] as? [AnyHashable: Any] ?? [:],
                                  category: event["category"] as? [AnyHashable: Any] ?? [:],
                                  extra: event["params"] as? [AnyHashable: Any] ?? [:]))
    }
}
