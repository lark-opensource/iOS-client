//
//  AssertReporter.swift
//  Todo
//
//  Created by 张威 on 2020/12/2.
//

import LKCommonsTracker
import LKCommonsLogging

struct AssertReporter {

    private static let slardarEventName = "todo_assert"

    /// Assert 配置
    struct AssertConfig {
        /// scene 和 event 分别描述场景和场景内的事件，命名建议下划线模式，eg:
        ///   scene: "detail", event: "create_todo"
        /// 相关信息进 category
        var scene: String
        var event: String

        static var `default` = AssertConfig(scene: "undefined", event: "undefined")
    }

    /// 上报 alert 到 slardar
    static func report(
        _ message: String,
        extra: [AnyHashable: Any] = .init(),
        config: AssertConfig = .default,
        file: String = #fileID,
        line: Int = #line
    ) {
        var extra = extra
        extra["msg"] = message
        extra["file"] = file
        extra["line"] = "\(line)"
        Tracker.post(SlardarEvent(
            name: slardarEventName,
            metric: [:],
            category: [
                "scene": config.scene,
                "event": config.event
            ],
            extra: extra
        ))
    }

}
