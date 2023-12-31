//
//  LarkMessageCardService.swift
//  LarkMessageCard
//
//  Created by ByteDance on 2022/12/5.
//

import Foundation
import LarkMessageBase

public protocol MessageCardContextManagerProtocol {
    func getContext(key: String) -> MessageCardContainer.Context?
    func setContext(key: String, context: MessageCardContainer.Context)
    func removeContext(key: String)
}

public final class MessageCardContextManager: MessageCardContextManagerProtocol {
    private let semaphore = DispatchSemaphore(value: 1)
    private var contexts: [String: MessageCardContainer.Context] = [:]
    
    public func getContext(key: String) -> MessageCardContainer.Context? {
        semaphore.wait(); defer { semaphore.signal() }
        return contexts[key]
    }
    
    public func setContext(key: String, context: MessageCardContainer.Context) {
        semaphore.wait(); defer { semaphore.signal() }
        contexts[key] = context
    }
    
    public func removeContext(key: String) {
        semaphore.wait(); defer { semaphore.signal() }
        contexts.removeValue(forKey: key)
    }
}
