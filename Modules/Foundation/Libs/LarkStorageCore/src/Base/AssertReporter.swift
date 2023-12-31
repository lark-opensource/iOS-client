//
//  Assert.swift
//  LarkStorage
//
//  Created by 7Up on 2022/8/8.
//

import Foundation

struct AssertReporter {

    static var enableAssertionFailure = true

    private static let eventName = "lark_storage_assert"

    struct AssertConfig {
        var scene: String
        var event: String
    }

    static func report(
        _ message: String,
        config: AssertConfig,
        extra: [AnyHashable: Any]? = nil,
        file: String = #fileID,
        line: Int = #line
    ) {
        var extra = extra ?? [:]
        extra["msg"] = message
        extra["file"] = file
        extra["line"] = "\(line)"

        Dependencies.post(TrackerEvent(
            name: eventName,
            metric: [:],
            category: [
                "scene": config.scene,
                "event": config.event
            ],
            extra: extra
        ))
    }

}
