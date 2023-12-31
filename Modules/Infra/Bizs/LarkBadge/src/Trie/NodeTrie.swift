//
//  Trie+Node.swift
//  LarkBadge
//
//  Created by KT on 2019/4/16.
//

import UIKit
import Foundation

// MARK: - Config the Node Trie by network or other trigger
protocol BadgeConfigable {

    /// 全局设置Badge
    ///
    /// - Parameter nodes: 网络解析/本地构造的 [BadgeNode]
    static func setBadge(_ nodes: [BadgeNode])

    /// 通过Node自定义Badge
    ///
    /// - Parameters:
    ///   - path: 目标节点完整路径
    ///   - info: 自定义节点
    static func setBadge(_ path: [NodeName], _ info: NodeInfo)

    /// 手动更新Badge数
    ///
    /// - Parameters:
    ///   - path: 目标节点完整路径
    ///   - count: Badge数
    static func setBadge(_ path: [NodeName], count: Int)

    /// 更新节点
    ///
    /// - Parameters:
    ///   - path: 目标节点完整路径
    ///   - newNode: 网络解析/本地构造的 BadgeNode
    static func updateBadge(_ path: [NodeName], newNode: BadgeNode)

    /// 清空Badge
    ///
    /// - Parameters:
    ///   - path: 目标节点完整路径
    ///   - force: 是否强制（默认false，即节点有子节点时无法清空）
    static func clearBadge(path: [NodeName], force: Bool)

    /// 目标节点Badge总数
    ///
    /// - Parameter path: 目标节点完整路径
    /// - Returns: Badge总数（当前count + 递归子节点count）
    static func totalCount(_ path: [NodeName]) -> Int
}

final class NodeTrie: BadgeConfigable {
    static var shared: Trie<BadgeNode> = Trie([])

    // setBadge by outside
    static func setBadge(_ nodes: [BadgeNode]) {
        shared = shared.insert(nodes)
        ObserveTrie.callRecursion(nodes.map { $0.name })
    }

    static func setBadge(_ path: [NodeName], _ info: NodeInfo) {
        // insert -> 把路径终点 makeElement
        if shared.node(path)?.isElement != true { shared.insert(path) }
        nodeGuarantee(path: path) {
            $0.info = info
            updateBadge(path, newNode: $0)
        }
    }

    static func setBadge(_ path: [NodeName], type: BadgeType, strategy: HiddenStrategy = .strong) {
        // insert -> 把路径终点 makeElement
        if shared.node(path)?.isElement != true { shared.insert(path) }
        nodeGuarantee(path: path) {

            // 读取初始化样式
            if let locoal = ObserveTrie.shared.node(path)?.info.observers.first?.controller?.locoalInfo {
                $0.info = locoal
            }
            $0.info.configPriorty = .locoal
            $0.info.type = type
            $0.info.strategy = strategy
            updateBadge(path, newNode: $0)
        }
    }

    static func insertWhenNotExist(_ path: [NodeName]) {
        if shared.node(path) == nil { shared.insert(path) }
    }

    // setBadge by hand
    static func setBadge(_ path: [NodeName], count: Int) {
        self.setBadge(path, type: .label(.number(count)))
    }

    static func updateBadge(_ path: [NodeName], hidden: Bool) {
        nodeGuarantee(path: path) {
            $0.info.isHidden = hidden
            updateBadge(path, newNode: $0)
        }
    }

    // update badge node
    static func updateBadge(_ path: [NodeName], newNode: BadgeNode) {
        guard  NodeTrie.shared.node(path) != nil else { return }
        // update recursion
        shared.update(path: path, newNode: newNode)
        ObserveTrie.callRecursion(path)

        // update combined observer
        guard let observer = ObserveTrie.shared.node(path) else { return }
        observer.linkedObserver.forEach { ObserveTrie.callRecursion($0) }
    }

    // clear
    static func clearBadge(path: [NodeName], force: Bool = false) {
        let childPath = shared.allChildrenPath(path: path)

        // clear count
        shared.delete(path, force: force)

        // 根据HiddenStrategy控制
        // 子节点全部是weak时，父节点才可以点击消除
        if isAllNodeStrategyEqual(path, to: .weak) {
            NodeTrie.updateBadge(path, hidden: true)
        }

        func callAndClearChildPath(_ path: [NodeName]) {
            ObserveTrie.call(path)

            // delete combined observer
            guard let observer = ObserveTrie.shared.node(path) else { return }
            observer.linkedObserver.forEach {
                // 如果关联点不是element， 递归删除
                if shared.node($0)?.isElement != true {
                    clearBadge(path: $0, force: force)
                } else {
                    // 如果关联点isElement，则不能取消,递归刷新
                    ObserveTrie.callRecursion($0)
                }
            }
        }

        // 强制删除 对子路径清空
        if force { childPath.forEach { callAndClearChildPath($0) } }

        // 删除当前路径
        path.recursionCall { callAndClearChildPath($0) }
    }

    // total (current + children)
    static func totalCount(_ path: [NodeName]) -> Int {
        return allBadgeNode(path).reduce(0) { $0 + $1.info.count }
    }

    // 关联的所有子节点
    static func allBadgeNode(_ path: [NodeName]) -> [BadgeNode] {
        var res: [BadgeNode] = []

        if let currentNode = shared.node(path), !res.contains(currentNode) {
            // current
            res += [currentNode]
        }

        // 递归子节点
        for childPath in NodeTrie.shared.nextChildrenPath(path: path) {
            res += allBadgeNode(childPath)
        }

        // 关联对象，对应的NodeTrie可能还没有
        for childPath in ObserveTrie.shared.nextChildrenPath(path: path) {
            if NodeTrie.shared.node(childPath) == nil {
                res += allBadgeNode(childPath)
            }
        }

        // 关联节点
        guard let observer = ObserveTrie.shared.node(path) else { return res }
        let combinedObserver = observer.info.observers.filter { !$0.primiry }
        guard !combinedObserver.isEmpty else { return res }
        for combined in combinedObserver where NodeTrie.shared.node(combined.path) != nil {
            for node in allBadgeNode(combined.path) where !res.contains(node) {
                res += [node]
            }
        }

        return res
    }

    // 第一个非.none节点
    static func firstDisplayNode(_ path: [NodeName]) -> BadgeNode? {
        let node = NodeTrie.allBadgeNode(path).sorted(by: <).first {
            if case .none = $0.info.type { return false }
            return true
        }
        return node
    }

    static func isAllNodeStrategyEqual(_ path: [NodeName], to strategy: HiddenStrategy) -> Bool {
        return allBadgeNode(path)
            .filter { $0.info.configPriorty != ConfigPriorty.none } // 非.none 节点
            .allSatisfy { $0.info.strategy == strategy }
    }

    static func forceClearAll() {
        shared = Trie([])
        ObserveTrie.callAll()
    }

    static func updateBadge(_ path: [NodeName], size: CGSize) {
        nodeGuarantee(path: path) {
            $0.info.size = size
            updateBadge(path, newNode: $0)
        }
    }

    static func updateBadge(_ path: [NodeName], cornerRadius: CGFloat) {
        nodeGuarantee(path: path) {
            $0.info.cornerRadius = cornerRadius
            updateBadge(path, newNode: $0)
        }
    }

    static func updateBadge(_ path: [NodeName], offset: CGPoint) {
        nodeGuarantee(path: path) {
            $0.info.offset = offset
            updateBadge(path, newNode: $0)
        }
    }

    @discardableResult
    private static func nodeGuarantee<T>(path: [NodeName], call: (_ node: inout BadgeNode) -> T) -> T? {
        guard var node = NodeTrie.shared.node(path) else { return nil }
        return call(&node)
    }
}
