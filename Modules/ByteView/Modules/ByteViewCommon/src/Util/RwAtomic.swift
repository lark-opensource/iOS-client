//
//  RwAtomic.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/7/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

@propertyWrapper
public final class RwAtomic<T> {
    private let lock = RwLock()
    private var value: T

    public init(wrappedValue: T) {
        self.value = wrappedValue
    }

    public var wrappedValue: T {
        get {
            return lock.withRead { value }
        }
        set {
            lock.withWrite { value = newValue }
        }
    }

    public func update(_ action: (inout T) -> Void) {
        lock.withWrite {
            action(&value)
        }
    }
}

public extension RwAtomic where T: Equatable {
    /// 仅在和原值不相等的时候设置
    /// - returns: 和原值不相等时返回true，否则返回false
    func setIfChanged(_ newValue: T) -> Bool {
        lock.withWrite {
            if value != newValue {
                value = newValue
                return true
            }
            return false
        }
    }
}
