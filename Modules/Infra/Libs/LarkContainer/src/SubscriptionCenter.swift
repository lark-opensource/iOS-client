//
//  SubscriptionCenter.swift
//  LarkContainer
//
//  Created by Li Yuguo on 2019/3/19.
//

import Foundation
public final class SubscriptionCenter {

    private let lock = NSRecursiveLock()
    private var subscriberRetainCount: [String: Int] = [:]

    public init() {}

    public func subscriberCount(eventName: String, block: ((Int) -> Void)?) {
        lock.lock()
        defer { lock.unlock() }

        block?(subscriberRetainCount[eventName] ?? 0)
    }

    public func increaseSubscriber(eventName: String, subscribeBlock: () -> Void) {
        lock.lock()
        defer { lock.unlock() }

        var retainCount = subscriberRetainCount[eventName] ?? 0
        retainCount += 1
        subscriberRetainCount[eventName] = retainCount
        if retainCount == 1 {
            subscribeBlock()
        }
    }

    public func decreaseSubscriber(eventName: String, unSubscribeBlock: () -> Void) {
        lock.lock()
        defer { lock.unlock() }

        if var retainCount = subscriberRetainCount[eventName] {
            retainCount -= 1
            subscriberRetainCount[eventName] = retainCount
            if retainCount == 0 {
                subscriberRetainCount.removeValue(forKey: eventName)
                unSubscribeBlock()
            }
        }
    }
}
