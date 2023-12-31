//
//  RwAtomic.swift
//  AudioSessionScenario
//
//  Created by fakegourmet on 2022/1/18.
//

import Foundation

@propertyWrapper
class RwAtomic<T> {
    private let lock = RwLock()
    private var value: T

    init(wrappedValue: T) {
        self.value = wrappedValue
    }

    var wrappedValue: T {
        get {
            return lock.withRead { value }
        }
        set {
            lock.withWrite { value = newValue }
        }
    }
}
