//
//  LogAppender.swift
//  Lark
//
//  Created by linlin on 2017/3/29.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation

public protocol Appender: AnyObject {

    static func identifier() -> String

    static func persistentStatus() -> Bool

    func doAppend(_ event: LogEvent)

    func commit()

    func persistent(status: Bool)

    func extractAdditionalData(additionalData: [String: String]) -> String

    func template(message: String, error: Error?) -> String

    /// log 在 debug 环境检测
    func debugLogRules() -> [LogRule]
}

/// Log 合法性规则
public protocol LogRule {
    var name: String { get }
    func check(event: LogEvent) -> Bool
}

extension Appender {
    public func extractAdditionalData(additionalData: [String: String]) -> String {
        guard !additionalData.isEmpty else { return "" }
        let additions = additionalData.keys.map { (k) -> String in
            return "\(k): \(additionalData[k] ?? "")"
        }.joined(separator: ", ")
        return "[\(additions)]"
    }

    public func template(message: String, error: Error?) -> String {
        var m = message
        if let error = error {
            m = "\(message) [Error|\(error)]"
        }
        return m
    }

    public func commit() {
    }

    public func debugLogRules() -> [LogRule] {
        return []
    }
}
