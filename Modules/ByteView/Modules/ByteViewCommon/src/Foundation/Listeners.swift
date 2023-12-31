//
//  Listeners.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/4/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

public final class Listeners<Element> {
    private let listeners = AnyListeners<AnyListener, Element>()

    public init() {}

    public var isEmpty: Bool { listeners.isEmpty }
    public var count: Int { listeners.count }
    public func contains(where predicate: (Element) -> Bool) -> Bool {
        listeners.compact().contains(where: predicate)
    }

    public func filter(_ predicate: (Element) -> Bool) -> [Element] {
        listeners.compact().filter(predicate)
    }

    public func forEach(_ body: (Element) throws -> Void) rethrows {
        try listeners.forEach(filter: { _ in true }, body: body)
    }

    public func addListener(_ listener: Element) {
        let obj = listener as AnyObject
        let id = ObjectIdentifier(obj)
        listeners.addListener { list in
            if list.contains(where: { $0.id == id }) {
                return
            }
            list.append(AnyListener(obj))
        }
    }

    public func removeListener(_ listener: Element) {
        listeners.removeListener(listener)
    }

    public func removeListener(by id: ObjectIdentifier) {
        listeners.removeListener(by: id)
    }

    public func removeAllListeners() {
        listeners.removeAllListeners()
    }
}

public final class HashListeners<Key: Hashable, Element> {
    private let listeners = AnyListeners<AnyHashListener<Key>, Element>()

    public init() { }

    public var isEmpty: Bool { listeners.isEmpty }
    public var count: Int { listeners.count }
    public func contains(where predicate: (Element) -> Bool) -> Bool {
        listeners.compact().contains(where: predicate)
    }

    public func first(for key: Key) -> Element? {
        listeners.first(where: { listener, _ in listener.keys.contains(key) })
    }

    public func invokeListeners(for key: Key, action: (Element) throws -> Void) rethrows {
        try invokeListeners(for: [key], action: action)
    }

    public func invokeListeners(for keys: Set<Key>, action: (Element) throws -> Void) rethrows {
        if keys.isEmpty { return }
        try listeners.forEach(filter: { !$0.keys.isDisjoint(with: keys) }, body: action)
    }

    public func addListener(_ listener: Element, for keys: Key...) {
        if keys.isEmpty { return }
        addListener(listener, for: Set(keys))
    }

    public func addListener(_ listener: Element, for keys: Set<Key>) {
        if keys.isEmpty { return }
        let obj = listener as AnyObject
        let id = ObjectIdentifier(obj)
        listeners.addListener { list in
            if let item = list.first(where: { $0.id == id }) {
                if item.keys != keys {
                    item.keys.formUnion(keys)
                }
                return
            }
            list.append(AnyHashListener(obj, keys: keys))
        }
    }

    public func removeListener(_ listener: Element) {
        listeners.removeListener(listener)
    }

    public func removeListener(by id: ObjectIdentifier) {
        listeners.removeListener(by: id)
    }

    public func removeAllListeners() {
        listeners.removeAllListeners()
    }
}

public final class BlockListeners<Element> {
    private let listeners = AnyListeners<AnyBlockListener<Element>, AnyObject>()

    public init() {}

    public var isEmpty: Bool { listeners.isEmpty }
    public var count: Int { listeners.count }

    public func send(_ element: Element) {
        listeners.compactRaw().forEach { $0.handler(element) }
    }

    public func addListener(_ listener: AnyObject, handler: @escaping (Element) -> Void) {
        listeners.addListener { list in
            list.append(AnyBlockListener(listener as AnyObject, handler: handler))
        }
    }

    public func removeListener(_ listener: AnyObject) {
        listeners.removeListener(listener)
    }

    public func removeAllListeners() {
        listeners.removeAllListeners()
    }
}

private class AnyListener {
    let id: ObjectIdentifier
    weak var ref: AnyObject?
    init(_ obj: AnyObject) {
        self.id = ObjectIdentifier(obj)
        self.ref = obj
    }
}

private class AnyHashListener<Key: Hashable>: AnyListener {
    var keys: Set<Key>
    init(_ obj: AnyObject, keys: Set<Key>) {
        self.keys = keys
        super.init(obj)
    }
}

private class AnyBlockListener<Element>: AnyListener {
    let handler: (Element) -> Void
    init(_ obj: AnyObject, handler: @escaping (Element) -> Void) {
        self.handler = handler
        super.init(obj)
    }
}

private final class AnyListeners<T: AnyListener, Element> {
    private let lock = RwLock()
    private var listeners: [T] = []

    var isEmpty: Bool {
        lock.withRead {
            listeners.first(where: { $0.ref != nil }) == nil
        }
    }

    var count: Int {
        lock.withRead {
            listeners.reduce(into: 0) { $0 += ($1.ref == nil ? 0 : 1) }
        }
    }

    func first(where predicate: (T, Element) -> Bool) -> Element? {
        lock.withRead {
            for obj in listeners {
                if let element = obj.ref as? Element, predicate(obj, element) {
                    return element
                }
            }
            return nil
        }
    }

    func forEach(filter: (T) -> Bool, body: (Element) throws -> Void) rethrows {
        var hasEmpty = false
        let items = lock.withRead {
            listeners.compactMap { obj in
                if let ref = obj.ref {
                    if let element = ref as? Element, filter(obj) {
                        return element
                    } else {
                        return nil
                    }
                } else {
                    hasEmpty = true
                    return nil
                }
            }
        }
        try items.forEach(body)
        if hasEmpty {
            lock.withWrite {
                listeners.removeAll(where: { $0.ref == nil })
            }
        }
    }

    func addListener(action: (inout [T]) -> Void) {
        lock.withWrite {
            // ObjectIdentifier 只有在对象生命周期内才有意义，
            // 已经释放的对象与新添加的对象ID可能相同，导致新对象addListener失败，因此优先清理失效对象
            listeners.removeAll(where: { $0.ref == nil })
            action(&listeners)
        }
    }

    func removeListener(_ listener: Element) {
        let obj = listener as AnyObject
        let id = ObjectIdentifier(obj)
        lock.withWrite {
            listeners.removeAll(where: { $0.ref == nil || $0.id == id })
        }
    }

    func removeListener(by id: ObjectIdentifier) {
        lock.withWrite {
            listeners.removeAll(where: { $0.ref == nil || $0.id == id })
        }
    }

    func removeAllListeners() {
        lock.withWrite {
            listeners.removeAll()
        }
    }

    func compact() -> [Element] {
        lock.withRead {
            listeners.compactMap {
                $0.ref as? Element
            }
        }
    }

    func compactRaw() -> [T] {
        lock.withRead {
            listeners.filter {
                $0.ref != nil
            }
        }
    }
}
