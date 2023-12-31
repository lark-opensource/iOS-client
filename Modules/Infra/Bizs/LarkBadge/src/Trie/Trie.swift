//
//  Trie.swift
//  LarkBadge
//
//  Created by KT on 2019/4/15.
//

import Foundation
import ThreadSafeDataStructure

extension TrieValueble {
    /// 设置该节点是否存储元素 eg: ABCD, 只有D节点是isElement
    ///
    /// - Parameter element: 指定该节点存储元素
    /// - Returns: Trie
    func setIsElement(_ element: Bool) -> Self {
        var node = self
        node.isElement = element
        return node
    }
}

// 字典树
final class Trie<T: TrieValueble> {
    typealias TrieMap = [NodeName: Trie<T>]
    // the node in current trie
    var node: T {
        get { return safeNode.value }
        set { safeNode.value = newValue }
    }
    private var safeNode: SafeAtomic<T> = Trie.root + .readWriteLock

    // the children trie in current trie
    var children: TrieMap {
        get { return safeChildren.value }
        set { safeChildren.value = newValue }
    }
    private var safeChildren: SafeAtomic<TrieMap> = [:] + .readWriteLock

    static var root: T { return T("TrieRoot") }
}

// MARK: - init
extension Trie {
    convenience init(_ nodes: [T], root: T = Trie.root) {
        if let (head, tail) = nodes.decompose {
            let children = [head.name: Trie(tail, root: head)]
            self.init(node: root, children: children)
        } else {
            self.init(node: root.setIsElement(true), children: [:])
        }
    }

    convenience init(node: T, children: TrieMap) {
        self.init()
        self.node = node
        self.children = children
    }
}

// MARK: - CRUD with Name
extension Trie {
    // insert
    func insert(_ paths: [NodeName]) {
        _ = insert(paths.map { T($0) }, replace: false)
    }

    // delete
    func delete(_ paths: [NodeName], force: Bool = false) {
        _ = delete(nodes: paths.map { T($0) }, force: force)
    }

    // find
    func find(_ paths: [NodeName]) -> Trie? {
        guard let (head, tail) = paths.decompose else { return self }
        guard let remainder = children[head] else { return  nil }
        return remainder.find(tail)
    }

    // 根据路径 返回目标字典树
    func trie(_ path: [NodeName]) -> Trie<T>? {
        return find(path)
    }

    // 根据路径返回目标字典树存储的节点
    func node(_ path: [NodeName]) -> T? {
        return trie(path)?.node
    }
}

// MARK: - CRUD
extension Trie {

    /// 插入节点
    ///
    /// - Parameters:
    ///   - nodes: 本地/网络 解析到的 `Nosew`
    ///   - replace: 是否替换之前节点
    ///   - root: 当前根节点
    /// - Returns: 插入后的Trie
    func insert(_ nodes: [T], replace: Bool = true, root: T = Trie.root) -> Trie {
        guard let (head, tail) = nodes.decompose else {
            return Trie(node: root.setIsElement(true), children: children)
        }

        if let nextTrie = self.children[head.name] {
            self.children[head.name] = nextTrie.insert(tail,
                                                     replace: replace,
                                                     root: nextTrie.update(head, replace: replace))
        } else {
            self.children[head.name] = Trie(tail, root: head)
        }
        return self
    }

    // update
    func update(_ newNode: T, replace: Bool) -> T {
        // 如果不需要替换，直接返回之前节点
        guard replace else { return self.node }
        // 更新Node(只更新node.info，主体结构不变)
        self.node.info = newNode.info
        return self.node
    }

    /// 把 A->B->C路径的C节点信息更新
    ///
    /// - Parameters:
    ///   - path: 目标节点路径
    ///   - newNode: 新节点信息
    /// - Returns: Trie
    func update(path: [NodeName], newNode: T) {
        guard let trie = find(path) else { return }
        trie.node = trie.update(newNode, replace: true)
    }

    /// 删除路径
    ///
    /// - Parameters:
    ///   - nodes: 路径数组
    ///   - force: 是否强制删除
    ///   - root: 递归当前root
    /// - Returns: 删除后新Trie
    func delete(nodes: [T], force: Bool = false) -> Trie {
        guard let (head, tail) = nodes.decompose else { return self }

        var newChildren = self.children
        guard let next = children[head.name] else { return self }
        // 递归删除
        newChildren[head.name] = next.delete(nodes: tail, force: force)

        guard let child = newChildren[head.name] else { return self }

        // delete 如果是leaf 先清空`isElement`
        if child.node == nodes.last, child.node.isElement {
            newChildren[head.name] = child.replace(node: child.node.setIsElement(false))
        }
        // 删除字典树路径
        if canDelete(child, leaf: nodes.last, force: force) {
            newChildren[head.name] = nil
        }
        return replace(children: newChildren)
    }

    func replace(children: TrieMap) -> Trie {
        self.children = children
        return self
    }

    func replace(node: T) -> Trie {
        self.node = node
        return self
    }

    /// 判断节点是否可以删除
    ///
    /// - Parameters:
    ///   - trie: 字典树
    ///   - leaf: 叶子
    ///   - force: 是否强制删除
    /// - Returns: 是否能删除
    func canDelete(_ trie: Trie, leaf: T?, force: Bool) -> Bool {
        // 非强制删除，必须没有叶子节点 || 强制删除只能删除指定叶子节点
        guard (trie.children.isEmpty) || (force && trie.node == leaf) else { return false }
        // 如果`isElement`，则需要保存子路径
        if trie.node.isElement && trie.node != leaf { return false }
        // 可以删除
        return true
    }
}

// MARK: - 遍历
extension Trie {
    // 深度遍历
    var elements: [[NodeName]] {
        var result: [[NodeName]] = (node.isElement && node != Trie.root) ? [[]] : []
        for (key, value) in children {
            result += value.elements.map { [key] + $0 }
        }
        return result
    }

    // 层次遍历
    var BFS: [Set<NodeName>] {
        var queue: [Trie] = []
        var res: [Set<NodeName>] = []
        queue.append(self)
        while !queue.isEmpty {
            let size = queue.count
            var level: Set<NodeName> = [] // 存放该层所有数值
            for _ in 0..<size {
                let trie = queue.removeFirst()
                level.insert(trie.node.name)
                for child in trie.children.values {
                    queue.append(child)
                }
            }
            res.append(level)
        }
        return res
    }

    func allNodes() -> [T] {
        return children.values.reduce([node]) { $0 + $1.allNodes() }
    }

    func allChildrenPath(path: [NodeName]) -> [[NodeName]] {
        var result: [[NodeName]] = []
        guard let trie = find(path) else { return result }
        trie.children.keys.forEach {
            result += [path + [$0]]
            result += allChildrenPath(path: path + [$0])
        }
        return result
    }

    func nextChildrenPath(path: [NodeName]) -> [[NodeName]] {
        var result: [[NodeName]] = []
        guard let trie = find(path) else { return result }
        trie.children.keys.forEach {
            result += [path + [$0]]
        }
        return result
    }
}

// MARK: - Helper
extension Array {
    var decompose: (Element, [Element])? {
        return isEmpty ? nil : ( self[startIndex], Array(self.dropFirst()) )
    }

    func recursionCall(_ action: (_ array: [Element]) -> Void) {
        guard !isEmpty else { return }
        action(self)
        self.dropLast().recursionCall(action)
    }
}
