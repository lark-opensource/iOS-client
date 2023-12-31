//
//  ThreadSafeContainer.swift
//  MailSDK
//
//  Created by larkmail on 2018/12/20.
//

// 扩充了部分接口的线程安全的集合 注意此处是class 而不是struct 是指针引用
// 需要用到其他的接口可自行扩充
final class ThreadSafeSet<T> where T: Hashable {
    private let semaphore = DispatchSemaphore(value: 1)
    private var safeSet: Set<T> = Set<T>()

    private func lock() {
        semaphore.wait()
    }

    private func unlock() {
        semaphore.signal()
    }

    deinit {
        unlock()
    }

    func count() -> Int {
        var  theCounter = 0
        lock()
        theCounter = self.safeSet.count
        unlock()
        return theCounter
    }

    func insert(_ newMember: T) {
       lock()
       self.safeSet.insert(newMember)
       unlock()
    }

    func remove(_ member: T) {
        lock()
        self.safeSet.remove(member)
        unlock()
    }

    func removeAll() {
        lock()
        self.safeSet.removeAll()
        unlock()
    }

    func contains(_ member: T) -> Bool {
        var hasObj = false
        lock()
        hasObj = self.safeSet.contains(member)
        unlock()
        return hasObj
    }
}

// 扩充了部分接口的字典 注意此处是class 而不是struct 是指针引用
// 需要用到其他的接口可自行扩充
final class ThreadSafeDictionary<Key, Value> where Key: Hashable {
    private var safeDict = [Key: Value]()
    typealias Element = (key: Key, value: Value)

    private let semaphore = DispatchSemaphore(value: 1)

    private func lock() {
        semaphore.wait()
    }

    private func unlock() {
        semaphore.signal()
    }

    deinit {
        unlock()
    }

    func all() -> [Key: Value] {
        var objects = [Key: Value]()
        lock()
        for (k, v) in safeDict {
            objects.updateValue(v, forKey: k)
        }
        unlock()
        return objects
    }

    func removeValue(forKey key: Key) -> Value? {
        var value: Value?
        lock()
        value = self.safeDict.removeValue(forKey: key)
        unlock()
        return value
    }

    func removeAll() {
      lock()
      self.safeDict.removeAll()
      unlock()
    }

    func count() -> Int {
        var  theCounter = 0
        lock()
        theCounter = self.safeDict.count
        unlock()
        return theCounter
    }

    func value(ofKey key: Key) -> Value? {
        var v: Value?
        lock()
        v = self.safeDict[key]
        unlock()
        return v
    }

    func updateValue(_ value: Value, forKey key: Key) {
        lock()
        self.safeDict.updateValue(value, forKey: key)
        unlock()
    }
}

// MARK: ThreadSafeDictionary 下标
extension ThreadSafeDictionary {
    subscript(key: Key) -> Value? {
        get {
            return self.value(ofKey: key)
        }
        set(newValue) {
            if let value = newValue {
                self.updateValue(value, forKey: key)
            } else {
                self.removeValue(forKey: key)
            }
        }
    }
}

// MARK: helper class
final class ThreadSafeArray<Element> {

    private var array: [Element] = [Element]()

    private let semaphore = DispatchSemaphore(value: 1)

    private func lock() {
        semaphore.wait()
    }

    private func unlock() {
        semaphore.signal()
    }

    deinit {
        unlock()
    }

    init(array: [Element]) {
        self.array = array
    }

    var isEmpty: Bool {
        var empty = true
        lock()
        empty = array.isEmpty
        unlock()
        return empty
    }

    var first: Element? {
        var item: Element?
        lock()
        item = array.first
        unlock()
        return item
    }

    var all: [Element] {
        var results = [Element]()
        lock()
        results = array
        unlock()
        return results
    }

    func append(newElement: Element) {
        lock()
        array.append(newElement)
        unlock()
    }

    func remove(at index: Int) {
        lock()
        array.remove(at: index)
        unlock()
    }

    func removeFirst() {
        lock()
        array.removeFirst()
        unlock()
    }

    func removeAll() {
        lock()
        array.removeAll()
        unlock()
    }

    @discardableResult
    func replaceAll(_ values: [Element]) -> [Element] {
        lock()
        array = values
        unlock()
        return values
    }
}
