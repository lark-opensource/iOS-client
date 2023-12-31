//
//  DataStructs.swift
//  AsyncComponent
//
//  Created by qihongye on 2019/3/12.
//

import Foundation

struct WeakRef<T: AnyObject> {
    weak var ref: T?
    init(_ ref: T) {
        self.ref = ref
    }
}

/// left mark false, and right mark true
/// [F, F, F, F, T, T, T, T, T]
struct MarkedArray<T> {
    struct Wrapper {
        var object: T
        var isActive: Bool = false
    }

    var nodes = [Wrapper]()
    private var splitIndex = 0

    init() {
    }

    var isEmpty: Bool {
        return nodes.isEmpty
    }

    var count: Int {
        return nodes.count
    }

    mutating func moveLeft(_ idx: Int) {
        if splitIndex < 0 {
            splitIndex = 0
            return
        }
        if splitIndex >= idx || splitIndex >= count {
            return
        }
        splitIndex = max(splitIndex - 1, 0)
        swapAt(splitIndex, idx)
    }

    mutating func moveRight(_ idx: Int) {
        if splitIndex <= 0 {
            return
        }
        let newSplitIndex = splitIndex - 1
        if idx != newSplitIndex {
            swapAt(newSplitIndex, idx)
        }
        splitIndex = newSplitIndex
    }

    @inline(__always)
    mutating func append(_ element: T) {
        nodes.append(Wrapper(object: element, isActive: true))
    }

    @inline(__always)
    mutating func reset(_ callback: @escaping (T) -> Void) {
        if splitIndex >= nodes.count {
            splitIndex = nodes.count
            return
        }
        for i in max(splitIndex, 0)..<nodes.count {
            callback(nodes[i].object)
            nodes[i].isActive = false
        }
        splitIndex = nodes.count
    }

    @inline(__always)
    mutating func get() -> T? {
        if splitIndex <= 0 {
            return nil
        }
        splitIndex -= 1
        nodes[splitIndex].isActive = true
        return nodes[splitIndex].object
    }

    @inline(__always)
    mutating func swapAt(_ lhs: Int, _ rhs: Int) {
        nodes.swapAt(lhs, rhs)
    }
}

final class ObjectPool<T: AnyObject> {
    fileprivate(set) var id: Int8 = 0
    private let factory: () -> T
    private let prepareForReuse: (T) -> Void
    private var markedArray = MarkedArray<T>()

    var count: Int {
        return markedArray.count
    }

    var idleElements: [T] {
        return markedArray.nodes.filter({ !$0.isActive }).map({ $0.object })
    }

    var elementActiveStates: [Bool] {
        return markedArray.nodes.map({ $0.isActive })
    }

    init(factory: @escaping () -> T,
         prepareForReuse: @escaping (T) -> Void) {
        self.factory = factory
        self.prepareForReuse = prepareForReuse
    }

    func borrowOne(expansion: Bool = false) -> T {
        if let object = markedArray.get() {
            return object
        }
        let object = factory()
        if expansion {
            markedArray.append(object)
            return object
        }
        return object
    }

    func returnAll() {
        // 依次释放所有的node
        markedArray.reset { (object) in
            self.prepareForReuse(object)
        }
    }
}

final class ObjectPoolManager<T: AnyObject> {
    struct Item {
        let pool: ObjectPool<T>
        var isActive: Bool = true
    }
    private var lock = os_unfair_lock_s()
    private var pools: [Int8: Item] = [:]
    private let factory: () -> T
    private let prepareForReuse: (T) -> Void

    init(factory: @escaping () -> T,
         prepareForReuse: @escaping (T) -> Void) {
        self.factory = factory
        self.prepareForReuse = prepareForReuse
    }

    func borrowPool() -> ObjectPool<T> {
        os_unfair_lock_lock(&lock)
        defer {
            os_unfair_lock_unlock(&lock)
        }
        for (key, item) in pools where !item.isActive {
            pools[key]?.isActive = true
            let pool = item.pool
            return pool
        }
        let pool = ObjectPool(factory: factory, prepareForReuse: prepareForReuse)
        let id = Int8(pools.count)
        pool.id = id
        pools[id] = Item(pool: pool)
        return pool
    }

    func returnPool(_ pool: ObjectPool<T>) {
        pool.returnAll()
        os_unfair_lock_lock(&lock)
        pools[pool.id]?.isActive = false
        os_unfair_lock_unlock(&lock)
    }

    func cleanMemory() {
        os_unfair_lock_lock(&lock)
        pools = [:]
        os_unfair_lock_unlock(&lock)
    }
}
