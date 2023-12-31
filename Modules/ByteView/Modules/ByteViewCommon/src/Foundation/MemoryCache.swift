//
//  MemoryCache.swift
//  ByteViewCommon
//
//  Created by kiri on 2023/2/15.
//

import Foundation
import EEAtomic

/// LRU内存缓存的简单实现，可设置数量和时间限制。
/// - cost限制使用频率过低，不做实现。
public final class MemoryCache: CustomStringConvertible {
    private let uuid: String
    private let countLimit: Int
    private let ageLimit: CFTimeInterval
    private let checkTimeoutInterval: DispatchTimeInterval
    private let checkTimeoutQueue: DispatchQueue?
    private let releaseQueue: DispatchQueue
    private var lock = UnfairLock()
    private var cache: [String: ValueNode] = [:]
    private var head: ValueNode?
    private var tail: ValueNode?

    /// 无数量和时间限制的内存缓存，收到MemoryWarning时会清空缓存。
    /// - 分开写初始化方法为了方便代码提示。
    public convenience init() {
        self.init(countLimit: 0)
    }

    /// LRU内存缓存的简单实现
    /// - parameters:
    ///     - countLimit: 缓存的数量上限。>0 为有效值，否则无限制。
    ///     - ageLimit: 缓存的时间限制，单位为秒。>0 为有效值，否则无限制。
    ///     - removeAllOnMemoryWarning: 是否在收到MemoryWarning时清空缓存，默认为true。
    public init(countLimit: Int, ageLimit: Int = 0, removeAllOnMemoryWarning: Bool = true) {
        self.uuid = Self.uuidGenerator.generate()
        let targetQueue = DispatchQueue.global(qos: .utility)
        self.releaseQueue = DispatchQueue(label: "ByteView.MemoryCache.\(uuid).Release", attributes: .concurrent, target: targetQueue)
        if countLimit > 0 {
            self.countLimit = countLimit
        } else {
            self.countLimit = 0
        }
        if ageLimit > 0 {
            self.ageLimit = CFTimeInterval(ageLimit)
            self.checkTimeoutInterval = .seconds(5)
            self.checkTimeoutQueue = DispatchQueue(label: "ByteView.MemoryCache.\(uuid).AgeLimit", attributes: .concurrent, target: targetQueue)
            checkTimeout()
        } else {
            self.ageLimit = 0
            self.checkTimeoutQueue = nil
            self.checkTimeoutInterval = .never
        }
        if removeAllOnMemoryWarning {
            NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMemoryWarning(_:)), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        }
    }

    public func value<T>(forKey key: String) -> T? {
        lock.lock()
        defer { lock.unlock() }
        if let node = cache[key] {
            self.use(node)
            return node.value as? T
        }
        return nil
    }

    public func value<T>(forKey key: String, type: T.Type) -> T? {
        value(forKey: key)
    }

    public func value<T>(forKey key: String, defaultValue: T) -> T {
        if let obj = value(forKey: key, type: T.self) {
            return obj
        } else {
            return defaultValue
        }
    }

    @discardableResult
    public func setValue(_ value: Any?, forKey key: String) -> Any? {
        guard let value = value else {
            return removeValue(forKey: key)
        }
        lock.lock()
        defer { lock.unlock() }
        let oldValue: Any?
        let node: ValueNode
        if let oldNode = cache[key] {
            node = oldNode
            oldValue = node.value
            node.value = value
            self.use(node)
        } else {
            oldValue = nil
            node = ValueNode(key: key, value: value)
            self.insert(node)
        }
        if countLimit > 0, self.cache.count > countLimit {
            if let tail = self.pop() {
                releaseQueue.async {
                    _ = tail.value // release in queue
                }
            }
        }
        return oldValue
    }

    @discardableResult
    public func removeValue(forKey key: String) -> Any? {
        lock.lock()
        defer { lock.unlock() }
        if let node = cache.removeValue(forKey: key) {
            node.next?.prev = node.prev
            node.prev?.next = node.next
            if head?.key == key {
                self.head = node.next
            }
            if tail?.key == key {
                self.tail = node.prev
            }
            releaseQueue.async {
                _ = node.value // release in queue
            }
            return node.value
        }
        return nil
    }

    public func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        let oldValues = self.cache
        cache = [:]
        head = nil
        tail = nil
        releaseQueue.async {
            _ = oldValues.count // release in queue
        }
    }

    public var description: String {
        "MemoryCache(\(uuid))"
    }

    @objc private func didReceiveMemoryWarning(_ notification: Notification) {
        removeAll()
    }

    private func checkTimeout() {
        checkTimeoutQueue?.asyncAfter(deadline: .now() + checkTimeoutInterval) { [weak self] in
            guard let self = self else { return }
            self.checkAgeLimit()
            self.checkTimeout()
        }
    }

    private func checkAgeLimit() {
        lock.lock()
        defer { lock.unlock() }
        let now = CACurrentMediaTime()
        guard let tail = self.tail, now - tail.time > ageLimit else { return }

        var holder: [ValueNode] = []
        while true {
            if let tail = self.tail, now - tail.time > ageLimit {
                if let node = self.pop() {
                    holder.append(node)
                }
            } else {
                break
            }
        }
        if !holder.isEmpty {
            releaseQueue.async {
                _ = holder.count // release in queue
            }
        }
    }

    private func use(_ node: ValueNode) {
        node.time = CACurrentMediaTime()
        if head == nil || tail == nil || head?.key == node.key {
            return
        }

        if tail?.key == node.key {
            tail = node.prev
            tail?.next = nil
        } else {
            node.next?.prev = node.prev
            node.prev?.next = node.next
        }
        node.next = head
        node.prev = nil
        head?.prev = node
        head = node
    }

    private func insert(_ node: ValueNode) {
        cache[node.key] = node
        if let head = self.head {
            node.next = head
            head.prev = node
            self.head = node
        } else {
            self.head = node
            self.tail = node
        }
    }

    private func pop() -> ValueNode? {
        guard let tail = self.tail else { return nil }
        cache.removeValue(forKey: tail.key)
        if head?.key == tail.key {
            self.head = nil
            self.tail = nil
        } else {
            self.tail = tail.prev
            self.tail?.next = nil
        }
        return tail
    }

    private static let uuidGenerator = UUIDGenerator()

    private class ValueNode {
        weak var prev: ValueNode?
        weak var next: ValueNode?
        let key: String
        var value: Any
        var time = CACurrentMediaTime()

        init(key: String, value: Any) {
            self.key = key
            self.value = value
        }
    }
}
