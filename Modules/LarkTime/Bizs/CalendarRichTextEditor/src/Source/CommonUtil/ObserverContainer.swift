//
//  ObserverContainer.swift
//  RichTextEditor
//
//  Created by chenhuaguan on 2020/6/30.
//

import Foundation

final class ObserverContainer<T> {
    private let observers: NSHashTable<AnyObject>
    private let lock = DispatchSemaphore(value: 1)

    init() {
        observers = NSHashTable(options: .weakMemory)
    }

    deinit {
        lock.signal()
    }

    func add(_ observer: T?) {
        guard let observer = observer else { return }
        lock.wait()
        self.observers.add(observer as AnyObject)
        lock.signal()
    }

    func remove(_ observer: T) {
        lock.wait()
        self.observers.remove(observer as AnyObject)
        lock.signal()
    }

    var all: [T] {
        var results = [T]()
        lock.wait()
        if let objs = self.observers.allObjects as? [T] {
            results = objs
        }
        lock.signal()
        return results
    }

}
