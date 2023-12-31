//
//  ObserverContainer.swift
//  SpaceKit
//
//  Created by 邱沛 on 2018/11/22.
//

import Foundation

public final class ObserverContainer<T> {
    private let observers: NSHashTable<AnyObject>
    private let lock = DispatchSemaphore(value: 1)

    public init() {
        observers = NSHashTable(options: .weakMemory)
    }

    deinit {
        lock.signal()
    }

    public func removeAll() {
        lock.wait()
        observers.removeAllObjects()
        lock.signal()
    }

    public func add(_ observer: T?) {
        guard let observer = observer else { return }
        lock.wait()
        self.observers.add(observer as AnyObject)
        lock.signal()
    }

    public func remove(_ observer: T) {
        lock.wait()
        self.observers.remove(observer as AnyObject)
        lock.signal()
    }

    public var all: [T] {
        var results = [T]()
        lock.wait()
        if let objs = self.observers.allObjects as? [T] {
            results = objs
        }
        lock.signal()
        return results
    }

//    /// warning 慎用此方法，如果有很变态的使用可能会引起死锁
//    /// 要遍历对象的话，可以调用all接口，再自行遍历分发消息
//    /// - Parameter block:
//    public func enumerateObjectUsing(block: (_ index: Int, _ obj: T) -> Void) {
//        lock.wait()
//        for (tId, tObj) in self.observers.allObjects.enumerated() {
//            guard let currentObj = tObj as? T else {
//                continue
//            }
//            block(tId, currentObj)
//        }
//        lock.signal()
//    }

}
