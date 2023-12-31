//
//  SafeLRUDictionary.swift
//  ThreadSafeDataStructure
//
//  Created by Saafo on 2021/5/26.
//

import Foundation

//swiftlint:disable no_space_in_method_call
//swiftlint 老版本有 bug，会误判只有一个 clousure 参数的方法调用

/// 线程安全的 LRU 字典
public final class SafeLRUDictionary<Key: Hashable, Value> {

    /// 最大容量，超过之后会自动移除最早加入字典的键值
    public var capacity: Int {
        get {
            synchronizationDelegate.readOperation {
                unsafeLRUDic.capacity
            }
        }
        set {
            synchronizationDelegate.writeOperation {
                unsafeLRUDic.capacity = newValue
            }
        }
    }

    /// 字典现有数量
    public var count: Int {
        synchronizationDelegate.readOperation {
            unsafeLRUDic.count
        }
    }

    /// 字典是否为空
    public var isEmpty: Bool {
        synchronizationDelegate.readOperation {
            unsafeLRUDic.isEmpty
        }
    }

    private let unsafeLRUDic: UnsafeLRUDictionary<Key, Value>

    //swiftlint:disable weak_delegate
    private let synchronizationDelegate: SynchronizationDelegate
    //swiftlint:enable weak_delegate

    /// 线程安全的 LRU 字典
    /// - Parameters:
    ///   - capacity: 字典容量，默认值为 100
    ///   - synchronization: 同步方法，因为 LRU 写更频繁，故默认值为 `semaphore`
    public init(capacity: Int = 100, synchronization: SynchronizationType = .semaphore) {
        self.unsafeLRUDic = UnsafeLRUDictionary(capacity: capacity)
        self.synchronizationDelegate = synchronization.generateSynchronizationDelegate()
    }

    /// 对字典设置值，同时更新使用顺序
    public func setValue(_ value: Value?, for key: Key) {
        synchronizationDelegate.writeOperation {
            unsafeLRUDic.setValue(value, for: key)
        }
    }

    /// 从字典取值
    /// - Parameters:
    ///   - update: 是否更新使用顺序，默认更新
    public func getValue(for key: Key, update: Bool = true) -> Value? {
        synchronizationDelegate.writeOperation {
            unsafeLRUDic.getValue(for: key)
        }
    }

    // MARK: Dictionary "protocol"

    /// 从字典取值，同时更新使用顺序
    public subscript(key: Key) -> Value? {
        get {
            getValue(for: key)
        }
        set {
            setValue(newValue, for: key)
        }
    }

    /// 遍历字典的 keys
    public var keys: [Key] {
        synchronizationDelegate.readOperation {
            unsafeLRUDic.keys
        }
    }

    /// 遍历字典的 values
    public var values: [Value] {
        synchronizationDelegate.readOperation {
            unsafeLRUDic.values
        }
    }

    /// 清空键值节点
    public func removeValue(forKey key: Key) -> Value? {
        synchronizationDelegate.writeOperation {
            return unsafeLRUDic.removeValue(forKey: key)
        }
    }

    /// 清空字典
    /// - Note: keepCapacity 默认为 true
    public func removeAll(keepingCapacity keepCapacity: Bool = true) {
        synchronizationDelegate.writeOperation {
            unsafeLRUDic.removeAll(keepingCapacity: keepCapacity)
        }
    }

}

/// 线程不安全的 LRU 字典
public final class UnsafeLRUDictionary<Key: Hashable, Value> {

    /// 节点数据结构
    struct CachePayload {
        let key: Key
        let value: Value
    }

    private var list = DoublyLinkedList<CachePayload>()
    private var nodesDict = [Key: DoublyLinkedList<CachePayload>.Node<CachePayload>]()

    public var capacity: Int {
        didSet {
            // only deal with smaller capacity
            guard capacity < oldValue else { return }
            if capacity < 0 {
                capacity = 0
            }
            while list.count > capacity {
                removeLast()
            }
        }
    }

    /// 字典现有数量
    public var count: Int {
        list.count
    }

    /// 字典是否为空
    public var isEmpty: Bool {
        list.isEmpty
    }

    /// 线程不安全的 LRU 字典
    /// - Parameters:
    ///   - capacity: 字典容量，默认值为 100
    public init(capacity: Int = 100) {
        self.capacity = max(0, capacity)
    }

    /// 对字典设置值，同时更新使用顺序
    public func setValue(_ value: Value?, for key: Key) {
        guard let value = value else {
            removeValue(forKey: key)
            return
        }
        let payload = CachePayload(key: key, value: value)

        if let node = nodesDict[key] {
            node.payload = payload
            list.moveToHead(node)
        } else {
            let node = list.addHead(payload)
            nodesDict[key] = node
        }

        if list.count > capacity {
            removeLast()
        }
    }

    /// 从字典取值
    /// - Parameters:
    ///   - update: 是否更新使用顺序，默认更新
    public func getValue(for key: Key, update: Bool = true) -> Value? {
        guard let node = nodesDict[key] else { return nil }
        list.moveToHead(node)
        return node.payload.value
    }

    // MARK: Dictionary "protocol"

    /// 从字典取值，同时更新使用顺序
    public subscript(key: Key) -> Value? {
        get {
            getValue(for: key)
        }
        set {
            setValue(newValue, for: key)
        }
    }

    /// 遍历字典的 keys
    public var keys: [Key] {
        nodesDict.keys.map { $0 }
    }

    /// 遍历字典的 values
    public var values: [Value] {
        nodesDict.values.map { $0.payload.value }
    }

    /// 移除指定节点
    @discardableResult
    public func removeValue(forKey key: Key) -> Value? {
        if let node = nodesDict[key] {
            list.removeNode(node)
            nodesDict[key] = nil
            return node.payload.value
        }
        return nil
    }

    /// 清空字典
    /// - Note: keepCapacity 默认为 true
    public func removeAll(keepingCapacity keepCapacity: Bool = true) {
        list = DoublyLinkedList<CachePayload>()
        nodesDict = [Key: DoublyLinkedList<CachePayload>.Node<CachePayload>]()
        if !keepCapacity {
            capacity = 100
        }
    }

    /// 移除最后一个节点
    private func removeLast() {
        let nodeRemoved = list.removeLast()
        if let key = nodeRemoved?.payload.key {
            nodesDict[key] = nil
        }
    }
}

/// 线程安全的双向链表
public final class SafeDoublyLinkedList<T> {

    //swiftlint:disable weak_delegate
    let synchronizationDelegate: SynchronizationDelegate
    //swiftlint:enable weak_delegate
    let list = DoublyLinkedList<T>()

    /// 链表长度
    public var count: Int {
        synchronizationDelegate.readOperation {
            list.count
        }
    }
    /// 链表是否为空
    public var isEmpty: Bool {
        synchronizationDelegate.readOperation {
            list.isEmpty
        }
    }
    /// 创建一个线程安全的双向链表
    public init(synchronization: SynchronizationType = .semaphore) {
        synchronizationDelegate = synchronization.generateSynchronizationDelegate()
    }

    /// 在链表头加入节点
    public func addHead(_ payload: T) -> DoublyLinkedList<T>.Node<T> {
        synchronizationDelegate.writeOperation {
            list.addHead(payload)
        }
    }

    /// 将节点移动至链表头
    public func moveToHead(_ node: DoublyLinkedList<T>.Node<T>) {
        synchronizationDelegate.writeOperation {
            list.moveToHead(node)
        }
    }

    /// 去掉链表末尾节点
    public func removeLast() -> DoublyLinkedList<T>.Node<T>? {
        synchronizationDelegate.writeOperation {
            list.removeLast()
        }
    }

    /// 移除节点
    public func removeNode(_ node: DoublyLinkedList<T>.Node<T>) {
        synchronizationDelegate.writeOperation {
            list.removeNode(node)
        }
    }
}

/// 通用的双向链表
public final class DoublyLinkedList<T> {

    /// 节点数据结构
    public final class Node<T> {
        var payload: T
        var previous: Node<T>?
        var next: Node<T>?

        init(payload: T) {
            self.payload = payload
        }
    }

    /// 链表长度
    public private(set) var count: Int = 0

    /// 链表是否为空
    public var isEmpty: Bool {
        //swiftlint:disable empty_count
        count == 0
        //swiftlint:enable empty_count
    }

    var head: Node<T>?
    var tail: Node<T>?

    /// 在链表头加入节点
    public func addHead(_ payload: T) -> Node<T> {
        let node = Node(payload: payload)
        defer {
            head = node
            count += 1
        }

        guard let head = head else {
            tail = node
            return node
        }

        head.previous = node

        node.previous = nil
        node.next = head

        return node
    }

    /// 将节点移动至链表头
    public func moveToHead(_ node: Node<T>) {
        guard node !== head else { return }
        let previous = node.previous
        let next = node.next

        previous?.next = next
        next?.previous = previous

        node.next = head
        head?.previous = node
        node.previous = nil

        if node === tail {
            tail = previous
        }

        self.head = node
    }

    /// 去掉链表末尾节点
    public func removeLast() -> Node<T>? {
        guard let tail = self.tail else { return nil }
        removeNode(tail)
        return tail
    }

    /// 移除节点
    public func removeNode(_ node: Node<T>) {
        let previous = node.previous
        let next = node.next
        next?.previous = previous
        previous?.next = next
        if previous != nil || next != nil || node === tail || node === head { // make sure the node is in the list
            count -= 1
        }
        if node === tail {
            tail = previous
        }
        if node === head {
            head = next
        }
        node.previous = nil // clear references
        node.next = nil
    }

    deinit { // deinit 时节点循环引用，需要手动清除节点
        while removeLast() != nil {}
    }
}

extension DoublyLinkedList: CustomStringConvertible where T: CustomStringConvertible {
    public var description: String {
        var string = "\(DoublyLinkedList.self): count: \(count), list: "
        var pointer: Node<T>? = head
        while let node = pointer {
            string += "[" + node.payload.description + "]"
            pointer = node.next
        }
        return string
    }
}
