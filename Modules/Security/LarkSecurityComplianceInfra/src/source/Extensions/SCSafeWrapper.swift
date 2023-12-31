//
//  SCSafeWrapper.swift
//  LarkSecurityComplianceInfra
//
//  Created by ByteDance on 2023/7/26.
//

import Foundation
import ThreadSafeDataStructure

@propertyWrapper
public struct SafeWrapper<T> {
    private var value: SafeAtomic<T>

    public var wrappedValue: T {
        get { value.value }
        set { value.value = newValue }
    }

    public init(wrappedValue: T) {
        self.value = wrappedValue + .readWriteLock
    }
}
