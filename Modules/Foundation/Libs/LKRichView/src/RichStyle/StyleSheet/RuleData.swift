//
//  RuleData.swift
//  LKRichView
//
//  Created by qihongye on 2019/11/12.
//

import Foundation

let ANY_TAG = "*"
let TEXT_TAG = "text"

final class RuleData {
    private let selectorIndex: Int

    let rule: StyleRule
    var selector: CSSSelector? {
        return rule.selectorList.selector(at: selectorIndex)
    }
    var properties: StyleProperties {
        return rule.properties
    }

    init(rule: StyleRule, selectorIndex: Int) {
        self.rule = rule
        self.selectorIndex = selectorIndex
    }
}

final class RuleSet {
    private var idRuleMap: [String: SortedArray<RuleData>] = [:]
    private var classRuleMap: [String: SortedArray<RuleData>] = [:]
    private var tagRuleMap: [Int: SortedArray<RuleData>] = [:]
    private(set) var universalRules: SortedArray<RuleData>

    init() {
        universalRules = SortedArray<RuleData>(areInIncreasingOrder: {
            $0.rule.priority < $1.rule.priority
        })
    }

    @inline(__always)
    func idRules(_ key: String) -> SortedArray<RuleData>? {
        return idRuleMap[key]
    }

    @inline(__always)
    func classRules(_ key: String) -> SortedArray<RuleData>? {
        return classRuleMap[key]
    }

    @inline(__always)
    func tagRules(_ key: Int) -> SortedArray<RuleData>? {
        return tagRuleMap[key]
    }

    func add(rule: StyleRule, selectorIndex: Int) {
        guard let selector = rule.selector else {
            return
        }
        let ruleData = RuleData(rule: rule, selectorIndex: selectorIndex)
        switch selector.match {
        case .id:
            if let value = selector.strValue {
                var rules = createSortedArrayIfNeeded(idRuleMap[value])
                rules.insert(ruleData)
                idRuleMap[value] = rules
            }
        case .className:
            if let value = selector.strValue {
                var rules = createSortedArrayIfNeeded(classRuleMap[value])
                rules.insert(ruleData)
                classRuleMap[value] = rules
            }
        case .tag:
            if selector.strValue == ANY_TAG || selector.strValue == TEXT_TAG {
                universalRules.insert(ruleData)
            } else if let value = selector.intValue {
                var rules = createSortedArrayIfNeeded(tagRuleMap[value])
                rules.insert(ruleData)
                tagRuleMap[value] = rules
            }
        case .unknown:
            break
        }

        if selector.relation == .directNeighbor,
            let prev = rule.selectorList.selector(at: selectorIndex - 1),
            prev.relation == .directNeighbor,
            prev.intValue != selector.intValue,
            prev.strValue != selector.strValue {
            // If prev.relation == selector.relation
            add(rule: rule, selectorIndex: selectorIndex - 1)
        }
    }

    @inline(__always)
    func createSortedArrayIfNeeded(_ array: SortedArray<RuleData>?) -> SortedArray<RuleData> {
        if let array = array {
            return array
        }
        return SortedArray<RuleData>(areInIncreasingOrder: {
            $0.rule.priority < $1.rule.priority
        })
    }
}
