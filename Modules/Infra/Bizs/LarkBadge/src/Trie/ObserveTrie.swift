//
//  Trie+Observer.swift
//  LarkBadge
//
//  Created by KT on 2019/4/16.
//

import UIKit
import Foundation

final class ObserveTrie {
    static var shared: Trie<ObserverNode> = Trie([])

    static func addObserve(_ path: [NodeName], with observer: Observer) {
        // insert if not found
        if shared.node(path) == nil {
            shared.insert(path)
        }
        guard var node = shared.node(path) else { return }
        guard !node.info.observers.contains(observer) else { return }
        node.info.observers.insert(observer, at: node.info.observers.startIndex)
        shared.update(path: path, newNode: node)
        call(path)
    }

    static func removeObserve(_ path: [NodeName], with info: Observer) {
        guard var node = shared.node(path) else { return }
        guard node.info.observers.contains(info) else { return }
        node.info.observers.removeAll { $0 == info }
        shared.update(path: path, newNode: node)

        // delete path if no observers exist
        if node.info.observers.isEmpty {
            shared.delete(path)
        }

        // Remove TrieNode as Root
        if path.count == 1 {
            NodeTrie.clearBadge(path: path, force: true)
        }
    }

    static func combine(targetPath: [NodeName], viewPath: [NodeName]) {
        if shared.node(targetPath) == nil {
            shared.insert(targetPath)
        }
        guard var targetObserver = shared.node(targetPath) else { return }
        if !targetObserver.linkedObserver.contains(viewPath) {
            targetObserver.linkedObserver.append(viewPath)

            // 替换为绑定关系后的节点
            guard let targetTrie = shared.find(targetPath) else { return }
            targetTrie.node = targetObserver
        }
    }

    static func allObserves(_ path: [NodeName]) -> [Observer]? {
        return ObserveTrie.shared.node(path)?.info.observers
    }

    static func call(_ path: [NodeName]) {
        DispatchQueue.main.mainSafe {
            guard let observerTrie = ObserveTrie.shared.trie(path) else { return }
            let observeInfo = observerTrie.node.info

            for observer in observeInfo.observers {
                // 所有关联的BadgeNode
                let nodes: [BadgeNode] = NodeTrie.allBadgeNode(path)

                if nodes.isEmpty {
                    // 没找到节点
                    observer.controller?.target?.badgeTarget?.badge.badgeView?.removeFromSuperview()
                } else {
                    // 更新UI
                    observer.controller?.target?.configBadgeView(observeInfo.observers, with: path)
                }
            }
        }
    }

    static func callRecursion(_ path: [NodeName]) {
        path.recursionCall { call($0) }
    }

    static func callAll() {
        shared.elements.forEach { callRecursion($0) }
    }

    static func clearAll() {
        shared = Trie([])
    }
}
