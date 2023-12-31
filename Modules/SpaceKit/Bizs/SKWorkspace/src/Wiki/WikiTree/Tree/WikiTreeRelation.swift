//
//  WikiTreeRelation.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/7/13.
//
// disable-lint: magic number

import Foundation
import SKFoundation

// 标识一棵树的父子节点关系
public struct WikiTreeRelation: Equatable {

    public struct NodeChildren: Equatable, Hashable, Comparable {
        // 节点 wiki token
        public let wikiToken: String
        // 节点 sortID，影响列表顺序
        public let sortID: Double

        public static func < (lhs: NodeChildren, rhs: NodeChildren) -> Bool {
            return lhs.sortID < rhs.sortID
        }
        
        public init(wikiToken: String, sortID: Double) {
            self.wikiToken = wikiToken
            self.sortID = sortID
        }
    }

    // 指向节点的父节点 wiki token
    public var nodeParentMap: [String: String] = [:]
    // 取到 nil 表示子节点尚未请求到，取到 [] 表明没有子节点
    public var nodeChildrenMap: [String: [NodeChildren]] = [:]

    public var isEmpty: Bool {
        guard nodeParentMap.isEmpty else { return false }
        guard nodeChildrenMap.isEmpty else { return false }
        return true
    }
    
    public init(nodeParentMap: [String : String] = [:], nodeChildrenMap: [String : [WikiTreeRelation.NodeChildren]] = [:]) {
        self.nodeParentMap = nodeParentMap
        self.nodeChildrenMap = nodeChildrenMap
    }

    // 初始化游离节点的子节点，主要为了初始化root节点使用，或在叶子节点转换为非叶子节点的时候使用
    public mutating func setup(rootToken: String) {
        nodeChildrenMap[rootToken] = []
    }

    // 插入时，会先从旧 parent 中移除
    public mutating func insert(wikiToken: String, sortID: Double, parentToken: String) {
        // 这里不判断 newParent 是否与旧 parent 相同，是为了从 nodeChildren 中先移除旧节点，避免子节点重复
        if nodeParentMap[wikiToken] != nil {
            DocsLogger.warning("parent exist when insert token, deleting before insert")
            delete(wikiToken: wikiToken)
        }

        guard var parentChildren = nodeChildrenMap[parentToken] else {
            // 父节点的子节点未请求到的时候，先不插入树中
            DocsLogger.warning("parent children is nil, insert skipped.")
            return
        }

        nodeParentMap[wikiToken] = parentToken

        let newChild = NodeChildren(wikiToken: wikiToken, sortID: sortID)
        if let index = parentChildren.firstIndex(where: { $0 > newChild }) {
            parentChildren.insert(newChild, at: index)
        } else {
            parentChildren.append(newChild)
        }
        nodeChildrenMap[parentToken] = parentChildren
    }

    // 不会从旧 parent 中移除，不会更新 parent 节点，用于收藏场景
    public mutating func forceInsert(wikiToken: String, sortID: Double, parentToken: String) {
        guard var parentChildren = nodeChildrenMap[parentToken] else {
            // 父节点的子节点未请求到的时候，先不插入树中
            DocsLogger.warning("parent children is nil, insert skipped.")
            return
        }

        let newChild = NodeChildren(wikiToken: wikiToken, sortID: sortID)
        if let index = parentChildren.firstIndex(where: { $0 > newChild }) {
            parentChildren.insert(newChild, at: index)
        } else {
            parentChildren.append(newChild)
        }
        nodeChildrenMap[parentToken] = parentChildren
    }

    // 删除一个节点的父子关系信息，会删除 parent 信息，也会从 parent 的 children 中删除
    public mutating func delete(wikiToken: String) {
        guard let parentToken = nodeParentMap[wikiToken] else {
            DocsLogger.warning("parent not found when remove token")
            return
        }
        defer {
            nodeParentMap[wikiToken] = nil
        }
        delete(wikiToken: wikiToken, parentToken: parentToken)
    }

    // 从特定 parent 的 children 中删除目标 token
    public mutating func delete(wikiToken: String, parentToken: String) {
        guard var parentChildren = nodeChildrenMap[parentToken] else {
            DocsLogger.error("parent children not found when remove token")
            return
        }
        parentChildren.removeAll { $0.wikiToken == wikiToken }
        nodeChildrenMap[parentToken] = parentChildren
    }

    public func getSortID(wikiToken: String) -> Double? {
        guard let parent = nodeParentMap[wikiToken] else {
            DocsLogger.error("get sortID failed, parent not found")
            return nil
        }
        guard let children = nodeChildrenMap[parent] else {
            DocsLogger.error("get sortID failed, children for parent not found")
            return nil
        }
        guard let node = children.first(where: { $0.wikiToken == wikiToken }) else {
            DocsLogger.error("get sortID failed, token not found in parent children")
            return nil
        }
        return node.sortID
    }

    // 获取根节点到特定 token 的路径，上层节点在前，不包括传入的 token
    public func getPath(wikiToken: String) -> [String] {
        var paths: [String] = []
        var parent = nodeParentMap[wikiToken]
        while let next = parent, !next.isEmpty {
            paths.append(next)
            parent = nodeParentMap[next]
        }
        return paths.reversed()
    }

    // 深度优先递归遍历获取一颗子树一致的所有 tokens，包括 rootWikiToken 自己，目前仅在删除的时候用到
    public func subTreeTokens(rootToken: String, level: Int = 0) -> [String] {
        // 递归深度限制
        if level >= 30 { return [] }
        var result = [rootToken]
        guard let children = nodeChildrenMap[rootToken]?.map(\.wikiToken) else {
            return result
        }
        children.forEach { childToken in
            result.append(contentsOf: subTreeTokens(rootToken: childToken, level: level + 1))
        }
        return result
    }

    // 带提前终止条件的深度优先遍历，判断一颗子树是否包含特定 token
    public func checkSubTree(rootToken: String, contains targetToken: String, level: Int = 0) -> Bool {
        if rootToken == targetToken { return true }
        if level >= 30 { return false }
        guard let children = nodeChildrenMap[rootToken]?.map(\.wikiToken) else {
            return false
        }
        return children.contains { childToken in
            checkSubTree(rootToken: childToken, contains: targetToken, level: level + 1)
        }
    }

    // 返回所有被删除的 tokens
    public mutating func deleteSubTree(rootToken: String, maxLevel: Int = 30) -> [String] {
        var result = [rootToken]
        guard let children = nodeChildrenMap[rootToken]?.map(\.wikiToken) else {
            delete(wikiToken: rootToken)
            clean(wikiToken: rootToken)
            return result
        }
        children.forEach { childToken in
            result.append(contentsOf: deleteSubTree(rootToken: childToken, level: 1, maxLevel: maxLevel))
        }
        // 首层递归调用的 delete 方法不太一样
        delete(wikiToken: rootToken)
        clean(wikiToken: rootToken)
        return result
    }

    private mutating func deleteSubTree(rootToken: String, level: Int, maxLevel: Int) -> [String] {
        var deletedTokens = [rootToken]
        defer {
            clean(wikiToken: rootToken)
        }
        if level >= maxLevel {
            DocsLogger.error("delete sub tree reach max level")
            return deletedTokens
        }
        guard let children = nodeChildrenMap[rootToken]?.map(\.wikiToken) else {
            return deletedTokens
        }
        children.forEach { childToken in
            deletedTokens.append(contentsOf: deleteSubTree(rootToken: childToken, level: level + 1, maxLevel: maxLevel))
        }
        return deletedTokens
    }

    private mutating func clean(wikiToken: String) {
        nodeParentMap[wikiToken] = nil
        nodeChildrenMap[wikiToken] = nil
    }

    public mutating func update(newRelation: WikiTreeRelation, onConflict: WikiTreeOperation.ConflictStrategy) {
        let newParentMap = newRelation.nodeParentMap
        var newRelation = newRelation
        newParentMap.forEach { (node, newParent) in
            if let oldParent = nodeParentMap[node],
               oldParent != newParent {
                if newParent.isEmpty, oldParent == WikiTreeNodeMeta.mutilTreeRootToken {
                    // 首页mvp知识库树下，知识库root_token的真实parent后端返回为"", 为了维护UI上的父子关系，保持知识库的parent为虚拟根token
                    return
                }
                switch onConflict {
                case .override:
                    // parent 冲突, 从 oldParent 的 children 中删除 node
                    delete(wikiToken: node)
                case .ignore:
                    // parent 冲突，从 newParent 的 children 中删除 node
                    newRelation.delete(wikiToken: node)
                    return
                }
            }
            // 没冲突或 override 模式，保存 newParent
            nodeParentMap[node] = newParent
        }

        nodeChildrenMap.merge(newRelation.nodeChildrenMap) {
            switch onConflict {
            case .override:
                return $1
            case .ignore:
                return $0
            }
        }
        #if DEBUG
        uniqueCheck()
        #endif
    }

    // 检查同一个节点是否出现在多个 parent 的 children 中
    func uniqueCheck() {
        var parentMap: [String: [String]] = [:]
        nodeChildrenMap.forEach { (parent, children) in
            children.forEach { child in
                var parents = parentMap[child.wikiToken] ?? []
                parents.append(parent)
                parentMap[child.wikiToken] = parents
            }
        }
        parentMap.forEach { (token, parents) in
            if parents.filter({ $0 != WikiTreeNodeMeta.favoriteRootToken && $0 != WikiTreeNodeMeta.sharedRootToken }).count > 1 {
                // 排除 收藏、与我分享根节点后，parent 数量超过 1，会导致 UID 冲突
                DocsLogger.debug("wiki tree relation unique check failed", extraInfo: ["token": token, "parents": parents])
                spaceAssertionFailure("wiki tree relation unique check failed")
            }
        }
    }
}
