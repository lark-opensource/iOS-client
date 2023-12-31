//
//  SecurityPolicyCodable.swift
//  LarkSecurityComplianceInterface
//
//  Created by ByteDance on 2022/11/15.
//

import Foundation

public protocol SecurityPolicyParser: Codable {
}

public extension SecurityPolicyParser {
    func asParams() -> [String: Any] {
            let data = (try? JSONEncoder().encode(self)) ?? Data()
            let results = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            return results ?? [:]
    }
}

public extension PolicyModel {
    var taskID: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(self),
              let str = String(data: data, encoding: .utf8) else { return "" }
        return str
    }
}
