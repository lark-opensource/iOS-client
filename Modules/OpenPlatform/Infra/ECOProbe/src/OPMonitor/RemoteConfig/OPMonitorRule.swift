//
//  OPMonitorRule.swift
//  LarkOPInterface
//
//  Created by yinyuan on 2020/5/26.
//

import Foundation

/// 过滤条件
class OPMonitorRuleFilter {

    /// 字段名
    let key: String?

    /// 字段枚举值白名单
    let values: [String]?

    /// 初始化过滤条件
    /// - Parameters:
    ///   - rawValue: 配置数据
    init(rawValue: [String: Any]) {
        self.key = rawValue["key"] as? String
        self.values = rawValue["values"] as? [String]
    }

    /// 匹配 data 中是否有 key-value 匹配此规则
    /// - Parameters:
    ///   - data: 待匹配的数据
    public func match(data: [String: Any]) -> Bool {
        guard let key = self.key, let values = self.values, let value = data[key] else {
            return false
        }
        let valueStr = "\(value)"
        return values.contains(valueStr)
    }
}

/// 采样规则
class OPMonitorRule {

    /// 优先级，默认值0
    public let priority: Int
    /// 采样率
    public let sampleRate: Float?
    /// 过滤条件列表（nil 一定不匹配，空数组一定匹配）
    public private(set) var filters: [OPMonitorRuleFilter]?

    /// 初始化采样规则
    /// - Parameters:
    ///   - rawValue: 配置数据
    init(rawValue: [String: Any]) {
        self.priority = rawValue["priority"] as? Int ?? 0
        self.sampleRate = rawValue["sample_rate"] as? Float

        if let filters = rawValue["filters"] as? [[String: Any]] {
            self.filters = filters.map { (filter) -> OPMonitorRuleFilter in
                return OPMonitorRuleFilter(rawValue: filter)
            }
        }
    }

    /// data 是否匹配此规则
    /// - Parameters:
    ///   - data: 待匹配的数据
    public func match(data: [String: Any]) -> Bool {
        guard let filters = self.filters else {
            return false
        }
        let missMatch = filters.contains { (filter) -> Bool in
            return !filter.match(data: data)
        }
        return !missMatch
    }

}
