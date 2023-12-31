//
//  LarkAITracker.swift
//  LarkAI
//
//  Created by chenyanjie on 2023/8/9.
//

import Foundation
import LKCommonsTracker
import LarkMessengerInterface
import LKCommonsLogging
import LarkContainer
import LarkSearchCore

final class LarkAITracker: NSObject {
    private static let logger = Logger.log(LarkAITracker.self, category: "LarkAITracker")
    public static func trackForStableWatcher(domain: String, message: String, metricParams: [String: Any]?, categoryParams: [String: Any]?) {
        guard enablePostTrack() else { return }
        guard !domain.isEmpty, !message.isEmpty else { return }
        var realCategoryParams: [String: Any] = [
            "asl_monitor_domain": domain,
            "asl_monitor_message": message
        ]
        categoryParams?.forEach({(key, value) in
            realCategoryParams[key] = value
        })
        Tracker.post(SlardarEvent(name: "asl_watcher_event", metric: metricParams ?? [:], category: realCategoryParams, extra: [:]))
    }
    public static func enablePostTrack() -> Bool {
        return SearchRemoteSettings.shared.enablePostStableTracker
    }
}
