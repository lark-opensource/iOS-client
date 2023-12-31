//
//  KVO+Extensions.swift
//  LarkFoundation
//
//  Created by Saafo on 2021/9/17.
//

import Foundation

public final class KVODisposeBag {

    private var lock = NSRecursiveLock()
    private var observations: [NSKeyValueObservation] = []

    public init() {
    }

    public func add(_ observation: NSKeyValueObservation) {
        _add(observation)
    }

    private func _add(_ observation: NSKeyValueObservation) {
        lock.lock()
        observations.append(observation)
        lock.unlock()
    }

    private func dispose() {
        observations.forEach {
            $0.invalidate()
        }
    }

    deinit {
        dispose()
    }
}

extension NSKeyValueObservation {
    public func disposed(by disposeBag: KVODisposeBag) {
        disposeBag.add(self)
    }
}
