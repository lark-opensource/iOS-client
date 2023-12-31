//
//  KeyValueService.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import EEAtomic

/// 描述不受统一存储管控的 KV
public enum KVUnmanaged {
    /// for UserDefault(suiteName:)
    case suiteName(String)
}

public final class KVManager {
    public static let shared = KVManager()

    private let lock = UnfairLock()
    private var unmanagedMap: [Space: [KVUnmanaged]] = [:]

    /// 注册未接入 LarkStorage 的 KV
    public func registerUnmanaged(_ unmanaged: KVUnmanaged, forSpace space: Space = .global) {
        lock.lock()
        defer { lock.unlock() }
        if self.unmanagedMap[space] == nil {
            self.unmanagedMap[space] = []
        }
        self.unmanagedMap[space]?.append(unmanaged)
    }
}
