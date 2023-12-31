//
//  CSSStyleRule.swift
//  LKRichView
//
//  Created by qihongye on 2019/11/5.
//

import Foundation

/// DataStructure as bellow:
/// div + p {
///     color: white;
/// }
/// selectorList[CSSSelector(div, directNeighbor), CSSSelector(p, subselector)]
/// properties[]
///
public class StyleRule {
    private var parentIsRule = false
    private(set) var selectorList: CSSSelectorList

    private weak var _parent: StyleRule?
    var parent: StyleRule? {
        get {
            if parentIsRule {
                return _parent
            }
            return nil
        }
        set {
            parentIsRule = true
            _parent = newValue
        }
    }

    private weak var _parentStyleSheet: CSSStyleSheet?
    var parentStyleSheet: CSSStyleSheet? {
        get {
            if parentIsRule {
                return parent?.parentStyleSheet
            }
            return _parentStyleSheet
        }
        set {
            parentIsRule = false
            _parentStyleSheet = newValue
        }
    }

    /// match from right to left
    var selector: CSSSelector? {
        return selectorList.last
    }

    var priority: UInt16 {
        return selectorList.priority
    }

    let properties: StyleProperties

    init(selectorList: CSSSelectorList, properties: StyleProperties) {
        self.selectorList = selectorList
        self.properties = properties
    }

    init(selectors: [CSSSelector], properties: StyleProperties) {
        self.selectorList = CSSSelectorList(selectors: selectors)
        self.properties = properties
    }

    @inline(__always)
    func match(node: Node) -> Bool {
        return selectorList.match(node)
    }
}

final class CSSSelectorList: Equatable {
    private var list: [CSSSelector]

    /// a, b, c ,d for 0xFFFF
    /// a: if style then a= 1, otherwise a = 0
    /// b: id selector's count
    /// c: count of classNames and pseudo-classes
    /// d: count of tags and pseudo-elements
    let priority: UInt16

    init(selectors: [CSSSelector]) {
        list = selectors
        priority = calcuatePriority(selectors)
    }

    var first: CSSSelector? {
        return list.first
    }

    var last: CSSSelector? {
        return list.last
    }

    var endIndex: Int {
        return list.endIndex
    }

    func selector(at: Int) -> CSSSelector? {
        guard at < list.count, at >= 0 else {
            return nil
        }
        return list[at]
    }

    func match(_ node: Node) -> Bool {
        guard let rightMost = last,
            rightMost.match(node) else {
            return false
        }
        let NONE_BACKTRACKING_IDX = -1
        var backTrackingIdx = NONE_BACKTRACKING_IDX
        var backTrackingNode: Node?
        var i = endIndex - 2

        var curNode: Node? = node
        while i >= 0 {
            let selector = list[i]
            switch selector.relation {
            case .child:
                guard let parent = curNode?.parent else {
                    return false
                }
                if !selector.match(parent) {
                    if backTrackingIdx != NONE_BACKTRACKING_IDX, let backNode = backTrackingNode {
                        i = backTrackingIdx
                        curNode = backNode
                        backTrackingIdx = NONE_BACKTRACKING_IDX
                        backTrackingNode = nil
                        continue
                    }
                    return false
                }
                curNode = parent
                i -= 1
            case .descendantSpace:
                guard let parent = curNode?.parent else {
                    return false
                }
                curNode = parent
                while curNode != nil {
                    if !selector.match(curNode!) {
                        curNode = curNode?.parent
                        continue
                    }
                    backTrackingIdx = i
                    backTrackingNode = curNode
                    i -= 1
                    break
                }
                if curNode == nil {
                    return false
                }
                continue
            case .directNeighbor:
                guard let prevSibling = curNode?.prevSibling else {
                    return false
                }
                if !selector.match(prevSibling) {
                    if backTrackingIdx != NONE_BACKTRACKING_IDX, let backNode = backTrackingNode {
                        i = backTrackingIdx
                        curNode = backNode
                        backTrackingIdx = NONE_BACKTRACKING_IDX
                        backTrackingNode = nil
                        continue
                    }
                    return false
                }
                curNode = prevSibling
                i -= 1
            case .subselector:
                if curNode == nil {
                    return false
                }
                if !selector.match(curNode!) {
                    if backTrackingIdx != NONE_BACKTRACKING_IDX, let backNode = backTrackingNode {
                        i = backTrackingIdx
                        curNode = backNode
                        backTrackingIdx = NONE_BACKTRACKING_IDX
                        backTrackingNode = nil
                        continue
                    }
                    return false
                }
                i -= 1
            }
        }
        return true
    }

    static func == (_ lhs: CSSSelectorList, _ rhs: CSSSelectorList) -> Bool {
        return lhs.list == rhs.list
    }
}

@inline(__always)
func calcuatePriority(_ list: [CSSSelector]) -> UInt16 {
    var b: UInt16 = 0
    var c: UInt16 = 0
    var d: UInt16 = 0

    for selector in list {
        switch selector.match {
        case .id:
            b += 1
        case .className:
            c += 1
        case .tag:
            d += 1
        case .unknown:
            continue
        }
    }
    return b << 8 + c << 4 + d
}

public protocol StyleSheet {
    var ownerNode: Node? { get set }
    var parent: StyleSheet? { get set }
    var disable: Bool { get set }
    var rules: [StyleRule] { get }
}

public final class CSSStyleSheet: StyleSheet {
    public var ownerNode: Node?

    public var parent: StyleSheet?

    public var disable: Bool = false

    public var rules: [StyleRule]

    public init(rules: [StyleRule] = []) {
        self.rules = rules
    }
}

public final class CSSStyleRule: StyleRule {
    public static func create(_ selectors: [CSSSelector], _ properties: [StyleProperty]) -> CSSStyleRule {
        return CSSStyleRule(selectors: selectors, properties: StyleProperties(properties))
    }

    public static func create(_ selector: CSSSelector, _ properties: [StyleProperty]) -> CSSStyleRule {
        return CSSStyleRule(selectors: [selector], properties: StyleProperties(properties))
    }
}

public struct CSSSelector: Equatable {
    public enum Match {
        case unknown
        case tag
        case id
        case className
    }

    public enum RelationType {
        case subselector
        case descendantSpace
        case child
        case directNeighbor
    }

    let match: Match
    var relation: RelationType

    let intValue: Int?
    let strValue: String?

    public init(match: Match, relation: RelationType = .subselector, value: String) {
        self.match = match
        self.relation = relation
        self.strValue = value
        self.intValue = nil
    }

    public init(match: Match, relation: RelationType = .subselector, value: Int) {
        self.match = match
        self.relation = relation
        self.intValue = value
        self.strValue = nil
    }

    public init<Tag: LKRichElementTag>(relation: RelationType = .subselector, value: Tag) {
        self.match = .tag
        self.relation = relation
        self.intValue = Int(value.typeID)
        self.strValue = nil
    }

    @inline(__always)
    func match(_ node: Node) -> Bool {
        switch match {
        case .id:
            return node.id == strValue
        case .className:
            guard let value = strValue else {
                return false
            }
            return node.hasClassName(value)
        case .tag:
            if strValue == ANY_TAG {
                return true
            }
            if strValue == TEXT_TAG, node.tag == -1 {
                return true
            }
            return Int(node.tag) == intValue
        case .unknown:
            return false
        }
    }

    public static func == (_ lhs: CSSSelector, _ rhs: CSSSelector) -> Bool {
        return lhs.match == rhs.match && lhs.relation == rhs.relation
            && lhs.intValue == rhs.intValue && lhs.strValue == rhs.strValue
    }
}

precedencegroup CSSOperator {
    associativity: left
    higherThan: AssignmentPrecedence
}

/// similar like subselector in css.
/// #div1.divClass == CSSSelctor(.id, "div1") <& CSSSelctor(.className, "divClass")
infix operator <&: CSSOperator
@inline(__always)
public func <& (_ lhs: CSSSelector, _ rhs: CSSSelector) -> [CSSSelector] {
    var lhs = lhs
    lhs.relation = .subselector
    return [lhs, rhs]
}
@inline(__always)
public func <& (_ lhs: [CSSSelector], _ rhs: CSSSelector) -> [CSSSelector] {
    if lhs.isEmpty {
        return [rhs]
    }
    var lhs = lhs
    lhs[lhs.endIndex - 1].relation = .subselector
    return lhs + [rhs]
}

/// similar like "space" in css.
/// .div .a == CSSSelctor(.className, "div") <| CSSSelctor(.className, "a")
infix operator <|: CSSOperator
@inline(__always)
public func <| (_ lhs: CSSSelector, _ rhs: CSSSelector) -> [CSSSelector] {
    var lhs = lhs
    lhs.relation = .descendantSpace
    return [lhs, rhs]
}
@inline(__always)
public func <| (_ lhs: [CSSSelector], _ rhs: CSSSelector) -> [CSSSelector] {
    if lhs.isEmpty {
        return [rhs]
    }
    var lhs = lhs
    lhs[lhs.endIndex - 1].relation = .descendantSpace
    return lhs + [rhs]
}

/// similar like ">" in css.
/// .div > .a == CSSSelctor(.className, "div") <>CSSSelctor(.className, "a")
infix operator <>: CSSOperator
@inline(__always)
public func <> (_ lhs: CSSSelector, _ rhs: CSSSelector) -> [CSSSelector] {
    var lhs = lhs
    lhs.relation = .child
    return [lhs, rhs]
}
@inline(__always)
public func <> (_ lhs: [CSSSelector], _ rhs: CSSSelector) -> [CSSSelector] {
    if lhs.isEmpty {
        return [rhs]
    }
    var lhs = lhs
    lhs[lhs.endIndex - 1].relation = .child
    return lhs + [rhs]
}

/// similar like "+" in css.
/// .div + .a == CSSSelctor(.className, "div") <+ CSSSelctor(.className, "a")
infix operator <+: CSSOperator
@inline(__always)
public func <+ (_ lhs: CSSSelector, _ rhs: CSSSelector) -> [CSSSelector] {
    var lhs = lhs
    lhs.relation = .directNeighbor
    return [lhs, rhs]
}
@inline(__always)
public func <+ (_ lhs: [CSSSelector], _ rhs: CSSSelector) -> [CSSSelector] {
    if lhs.isEmpty {
        return [rhs]
    }
    var lhs = lhs
    lhs[lhs.endIndex - 1].relation = .directNeighbor
    return lhs + [rhs]
}
