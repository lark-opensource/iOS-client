//
//  Transaction.swift
//  AsyncComponent
//
//  Created by qihongye on 2019/3/10.
//

import Foundation

private var _idx = Int32.min
private var _transactionSet = Set<Transaction>()

private let _transactionGroupRunLoopObserverCallback: CFRunLoopObserverCallBack = { (_, _, _) in
    if _transactionSet.isEmpty {
        return
    }
    let currentSet = _transactionSet
    _transactionSet = Set<Transaction>()

    for transaction in currentSet {
        transaction.render()
    }
}

final class Transaction: Hashable {
    static var setup: Bool = {
        let runloop = CFRunLoopGetMain()
        let observer = CFRunLoopObserverCreate(
            kCFAllocatorDefault,
            CFRunLoopActivity.beforeWaiting.rawValue | CFRunLoopActivity.exit.rawValue,
            true,
            0xFFFF,
            _transactionGroupRunLoopObserverCallback,
            nil
        )
        CFRunLoopAddObserver(runloop, observer, .commonModes)
        return true
    }()

    var hashValue: Int

    var displayBlock: () -> Void

    init(id: Int? = nil, display: @escaping () -> Void) {
        hashValue = id ?? Int(OSAtomicIncrement32Barrier(&_idx))
        self.displayBlock = display
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(hashValue)
    }

    func render() {
        displayBlock()
    }

    func commit() {
        //用后面的覆盖前面的
        _transactionSet.remove(self)
        _transactionSet.insert(self)
    }

    static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
