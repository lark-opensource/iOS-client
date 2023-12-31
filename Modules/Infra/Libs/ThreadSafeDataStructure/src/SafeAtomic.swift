//
//  SafeAtomic.swift
//  LarkLocalizations
//
//  Created by PGB on 2019/11/29.
//

import Foundation

/// Init a 'SafeAtomic' by using a value and a designated synchronization primtive
/// - Parameter value: Inner data of the wrapper
/// - Parameter synchronization: The synchronization primtive type used in this safeAtomic
public func + <T>(value: T, synchronization: SynchronizationType) -> SafeAtomic<T> {
    return SafeAtomic(value, with: synchronization)
}

/// A wrapper for safe accessing
///
/// Checkout the [guidebook](https://bytedance.feishu.cn/space/doc/doccnNb7YCSPctnUGmWNEUs3Ywh) to get started with more information
public final class SafeAtomic<T> {
    /// inner value of the wrapper class
    public var value: T {
        get {
            synchronizationDelegate.readOperation {
                return data
            }
        }
        set {
            synchronizationDelegate.writeOperation {
                data = newValue
            }
        }
    }

    private var data: T
    private let synchronizationDelegate: SynchronizationDelegate

    /// Creates a thread-safe instance by given value and SynchronizationType
    public init(_ value: T, with synchronization: SynchronizationType) {
        self.data = value
        self.synchronizationDelegate = synchronization.generateSynchronizationDelegate()
    }

    /// Accesses the inner value under shared lock.
    /// You can also safely access the attributes(if has) of the inner value if you only use safeRead() and safeWrite()
    /// - Parameter action: The action to run on the value
    public func safeRead(action: ((T) -> Void)) {
       synchronizationDelegate.readOperation {
           action(data)
       }
    }

    /// Accesses the inner value under exclusive lock.
    /// You can also safely access the attributes(if has) of the inner value if you only use safeRead() and safeWrite()
    /// - Parameter action: The action to run on the value
    public func safeWrite(action: ((inout T) -> Void)) {
       synchronizationDelegate.writeOperation {
           action(&data)
       }
    }
}
