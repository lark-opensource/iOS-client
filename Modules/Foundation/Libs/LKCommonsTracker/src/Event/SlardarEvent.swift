//
//  SlardarEvent.swift
//  LKCommonsTracker
//
//  Created by 李晨 on 2019/3/25.
//

import Foundation

// Slardar 基础 event
public final class SlardarEvent: Event {
    public var metric: [AnyHashable: Any]
    public var category: [AnyHashable: Any]
    public var extra: [AnyHashable: Any]
    public var immediately: Bool

    public init(
        name: String,
        metric: [AnyHashable: Any],
        category: [AnyHashable: Any],
        extra: [AnyHashable: Any],
        immediately: Bool = false) {
        self.metric = metric
        self.category = category
        self.extra = extra
        self.immediately = immediately
        super.init(name: name)
    }
}

// Slardar 自定义服务 事件
// 对应接口 track(data: [AnyHashable: Any], logType: String)
public final class SlardarCustomEvent: Event {
    public var params: [AnyHashable: Any]
    public init(name: String, params: [AnyHashable: Any]) {
        self.params = params
        super.init(name: name)
    }
}
