//
//  ThreadSafeContainer.swift
//  SpaceKit
//
//  Created by Webster on 2018/12/20.
//

import RxSwift
import RxCocoa

// 扩充了部分接口的线程安全的集合 注意此处是class 而不是struct 是指针引用
// 需要用到其他的接口可自行扩充
public final class ThreadSafeSet<T> where T: Hashable {

    var observableCount: Observable<Int> {
        return _observableCount.asObservable()
    }
    private let _observableCount: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)

    private let semaphore = DispatchSemaphore(value: 1)
    var safeSet: Set<T> = Set<T>()

    public init() { }
    
    deinit {
        unlock()
    }

    public func popFirst() -> T? {
        return self.safeSet.popFirst()
    }

    public func first() -> T? {
        return self.safeSet.first
    }

    public func isEmpty() -> Bool {
        return safeSet.isEmpty
    }

    public func count() -> Int {
        var  theCounter = 0
        lock()
        theCounter = self.safeSet.count
        unlock()
        return theCounter
    }

    public func insert(_ newMember: T) {
        lock()
        self.safeSet.insert(newMember)
        self._observableCount.accept(self.safeSet.count)
        unlock()
    }

    public func remove(_ member: T) {
        lock()
        self.safeSet.remove(member)
        self._observableCount.accept(self.safeSet.count)
        unlock()
    }

    public func removeAll() {
        lock()
        self.safeSet.removeAll()
        self._observableCount.accept(self.safeSet.count)
        unlock()
    }

    public func contains(_ member: T) -> Bool {
        var hasObj = false
        lock()
        hasObj = self.safeSet.contains(member)
        unlock()
        return hasObj
    }

//    public func enumerateObjectUsingBlock(_ block: (_ obj: T) -> Void) {
//        lock()
//        for obj in self.safeSet {
//            block(obj)
//        }
//        unlock()
//    }
    //补集
    public func subtracting(_ other: ThreadSafeSet<T>) -> ThreadSafeSet<T> {
        let newObj = ThreadSafeSet<T>()
        lock()
        let resultSet = self.safeSet.subtracting(other.safeSet)
        newObj.safeSet = resultSet
        unlock()
        return newObj
    }

    private func lock() {
        semaphore.wait()
    }

    private func unlock() {
        semaphore.signal()
    }
}

// 扩充了部分接口的字典 注意此处是class 而不是struct 是指针引用
// 需要用到其他的接口可自行扩充
public final class ThreadSafeDictionary<Key, Value> where Key: Hashable {
    private let semaphore = DispatchSemaphore(value: 1)
    public var safeDict = [Key: Value]()
//    typealias Element = (key: Key, value: Value)

    public init() { }

    deinit {
        unlock()
    }

    public func all() -> [Key: Value] {
        var objects = [Key: Value]()
        lock()
        for (k, v) in safeDict {
            objects.updateValue(v, forKey: k)
        }
        unlock()
        return objects
    }

    public func removeValue(forKey key: Key) {
        lock()
        self.safeDict.removeValue(forKey: key)
        unlock()
    }

//    public func filter(_ isInclude: (Key, Value) -> Bool) -> ThreadSafeDictionary<Key, Value> {
//        let newDictionary = ThreadSafeDictionary<Key, Value>()
//        lock()
//        let result: [Key: Value] = self.safeDict.filter(isInclude)
//        newDictionary.safeDict = result
//        unlock()
//        return newDictionary
//    }

    public func count() -> Int {
        var  theCounter = 0
        lock()
        theCounter = self.safeDict.count
        unlock()
        return theCounter
    }

    public func value(ofKey key: Key) -> Value? {
        var v: Value?
        lock()
        v = self.safeDict[key]
        unlock()
        return v
    }

    public func removeAll() {
        lock()
        self.safeDict.removeAll()
        unlock()
    }

    public func updateValue(_ value: Value, forKey key: Key) {
        lock()
        self.safeDict.updateValue(value, forKey: key)
        unlock()
    }

    public func enumerateObjectUsingBlock(_ block: (_ key: Key, _ value: Value) -> Void) {
        lock()
        for (k, v) in self.safeDict {
            block(k, v)
        }
        unlock()
    }

    private func lock() {
        semaphore.wait()
    }

    private func unlock() {
        semaphore.signal()
    }
}
