//
//  CSSStyleEngine.swift
//  LKRichView
//
//  Created by qihongye on 2019/12/27.
//

import Foundation

final class CSSStyleEngine {
    private let cssruleSet: RuleSet

    init(_ sheets: [StyleSheet]) {
        cssruleSet = RuleSet()
        for sheet in sheets where !sheet.disable {
            for rule in sheet.rules {
                cssruleSet.add(rule: rule, selectorIndex: rule.selectorList.endIndex - 1)
            }
        }
    }

    func load(sheet: StyleSheet) {
        if !sheet.disable {
            for rule in sheet.rules {
                cssruleSet.add(rule: rule, selectorIndex: rule.selectorList.endIndex - 1)
            }
        }
    }

    func createRenderStyle(node: Node) -> LKRenderRichStyle {
        let properties = node.defaultStyleProperties
        for rule in cssruleSet.universalRules where rule.rule.match(node: node) {
            properties.mergeProperties(rule.properties)
        }
        /// Priority: tag < class < id < style
        if let rules = cssruleSet.tagRules(Int(node.tag)) {
            for rule in rules where rule.rule.match(node: node) {
                properties.mergeProperties(rule.properties)
            }
        }
        if !node.classNames.isEmpty {
            let rules = node.classNames
                .compactMap { cssruleSet.classRules($0) }
                .flatMap { $0 }
            for rule in rules where rule.rule.match(node: node) {
                properties.mergeProperties(rule.properties)
            }
        }
        if !node.id.isEmpty, let rules = cssruleSet.idRules(node.id) {
            for rule in rules where rule.rule.match(node: node) {
                properties.mergeProperties(rule.properties)
            }
        }

        properties.applyToRenderStyle(node)
        return node.style.storage
    }
}
