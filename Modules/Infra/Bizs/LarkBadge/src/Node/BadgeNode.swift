//
//  Node.swift
//  LarkBadge
//
//  Created by KT on 2019/4/15.
//

import Foundation

public struct BadgeNode: TrieValueble {
    typealias UpdateInfo = NodeInfo

    // updatable
    var info: UpdateInfo = NodeInfo(.none)

    var name: NodeName
    var isElement: Bool = false
    init(_ name: NodeName) {
        self.name = name
    }
}

extension BadgeNode: Equatable, Hashable, Comparable {
    public static func == (lhs: BadgeNode, rhs: BadgeNode) -> Bool {
        // 判断节点是否相当，目前只通过name
        return lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(isElement)
    }

    public static func < (node1: BadgeNode, node2: BadgeNode) -> Bool {
        // 节点子节点列表，返回优先级高的，用于多个子节点合并功能
        return node1.info.type.childPriority > node2.info.type.childPriority
    }
}
