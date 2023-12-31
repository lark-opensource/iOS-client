//
//  RwLock.swift
//  LarkMedia
//
//  Created by fakegourmet on 2022/11/17.
//

import Foundation
import EEAtomic

final class RwLock {
    private var lock = EEAtomic.RWLock()

    init() {}

    func withRead<T>(_ block: () throws -> T) rethrows -> T {
        try lock.withRDLocking(action: block)
    }

    func withWrite<T>(_ block: () throws -> T) rethrows -> T {
        try lock.withWRLocking(action: block)
    }
}
