//
//  MessageCardContextManagerProtocol.swift
//  UniversalCard
//
//  Created by ByteDance on 2023/8/7.
//

import Foundation
import UniversalCardInterface
public final class UniversalCardContextManager: UniversalCardContextManagerProtocol {
    private let semaphore = DispatchSemaphore(value: 1)
    private var contexts: [String: UniversalCardContext] = [:]

    public init() {}

    public func getContext(key: String) -> UniversalCardContext? {
        semaphore.wait(); defer { semaphore.signal() }
        return contexts[key]
    }

    public func setContext(key: String, context: UniversalCardContext) {
        semaphore.wait(); defer { semaphore.signal() }
        contexts[key] = context
    }

    public func removeContext(key: String) {
        semaphore.wait(); defer { semaphore.signal() }
        contexts.removeValue(forKey: key)
    }
}
