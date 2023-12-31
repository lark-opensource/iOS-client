//
//  Monitor.swift
//  EENavigator
//
//  Created by xiongmin on 2021/9/24.
//

import Foundation
import LKCommonsTracker

final class Monitor {

    static let name = "lark_navigator_monitor"

    static func upload(error: RouterError) {
        let category: [String: Any] = [
            "error_code": error.code,
            "open_type": error.openType.rawValue
        ]
        let extra = [
            "message": error.message,
            "from": error.fromViewController ?? "",
            "url": error.url ?? ""
        ]
        let event = SlardarEvent(name: name, metric: [:], category: category, extra: extra)
        Tracker.post(event)
    }

}
