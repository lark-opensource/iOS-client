//
//  SignalTrap.swift
//  LarkOpenChat
//
//  Created by qihongye on 2020/12/6.
//

import Foundation

/// 信号监听者
public protocol Listener: AnyObject {
    /// 监听某信号时，该信号如果之前收到过，是否应该直接触发on(event)方法
    var replyLatestWhenListen: Bool { get }

    /// 接受到某个信号
    func on(event: Event)
}

/// 用来传递Chat中一些通用的事件
public final class SignalTrap {
    /// 信号监听者
    public struct Listeners {
        /// 该信号的监听者
        var handlers: [Listener] = []
        /// 记录上一次收到的信号
        var lastEvent: Event?

        init() {
            self.handlers.reserveCapacity(10)
        }

        mutating func send(event: Event) {
            self.handlers.forEach({ $0.on(event: event) })
            self.lastEvent = event
        }
    }

    /// 信号 -> 监听者
    private var listeners: [String: Listeners] = [:]
    private var rwlock = pthread_rwlock_t()

    /// init
    public init() {
        pthread_rwlock_init(&rwlock, nil)
    }

    /// 添加某个信号的监听者
    public func listen(to event: Event.Type, listener: Listener) {
        pthread_rwlock_wrlock(&rwlock)
        var listeners = self.listeners[event.name] ?? Listeners()
        listeners.handlers.append(listener)
        self.listeners[event.name] = listeners
        pthread_rwlock_unlock(&rwlock)
        // 是否需要直接触发信号
        if let lastEvent = listeners.lastEvent, listener.replyLatestWhenListen {
            listener.on(event: lastEvent)
        }
    }

    /// 发送信号
    public func trap(event: Event) {
        pthread_rwlock_wrlock(&rwlock)
        // 如果没有监听者监听该信号，则应该填充默认值，如果后续有监听者replyLatestWhenListen为true，则可以直接发送信号
        if self.listeners[event.name] == nil {
            self.listeners[event.name] = Listeners()
        }
        self.listeners[event.name]?.send(event: event)
        pthread_rwlock_unlock(&rwlock)
    }
}
