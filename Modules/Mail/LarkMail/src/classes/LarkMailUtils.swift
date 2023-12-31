//
//  LarkMailUtils.swift
//  LarkMail
//
//  Created by tefeng liu on 2020/7/7.
//

import Foundation
import ThreadSafeDataStructure

@propertyWrapper
struct Atomic<T> {
    private let value: SafeAtomic<T>

    init(_ value: T) {
        self.value = SafeAtomic(value, with: .readWriteLock)
    }

    var wrappedValue: T {
        mutating get {
            value.value
        }
        set {
            self.value.value = newValue
        }
    }
}
