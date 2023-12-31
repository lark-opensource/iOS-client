//
//  PushReceiver.swift
//  ByteViewNetwork
//
//  Created by kiri on 2023/2/15.
//

import Foundation
import ByteViewCommon

public final class PushReceiver<T> {
    private let logger = Logger.push
    /// 是否缓存旧值（全局缓存）
    fileprivate let shouldCacheLast: Bool

    @RwAtomic
    fileprivate var lastPacket: PushPacket<T>?
    private let dispatchers = Listeners<PushDispatcher<T>>()

    init(shouldCacheLast: Bool = false) {
        self.shouldCacheLast = shouldCacheLast
    }

    fileprivate func addDispatcher(_ observer: PushDispatcher<T>) {
        dispatchers.addListener(observer)
    }

    fileprivate func removeDispatcher(_ observer: PushDispatcher<T>) {
        dispatchers.removeListener(observer)
    }

    public func shouldConsumePacket(_ packet: RawPushPacket) -> Bool {
        shouldCacheLast || dispatchers.contains(where: { $0.shouldHandleRawPacket(packet) })
    }

    public func consumePacket(_ packet: PushPacket<T>) {
        if self.shouldCacheLast {
            self.lastPacket = packet
        }
        let obs = self.dispatchers.filter { $0.shouldHandlePacket(packet) }
        obs.forEach {
            $0.willHandlePushPacket(packet)
        }
        obs.forEach {
            $0.handlePushPacket(packet)
        }
        obs.forEach {
            $0.didHandlePushPacket(packet)
        }
    }

    public func inUser(_ userId: String, cacheLast: Bool = false) -> PushDispatcher<T> {
        let dispatcher: PushDispatcher<T> = PushDispatcher(userId: userId, shouldCacheLast: cacheLast)
        self.addDispatcher(dispatcher)
        if cacheLast {
            Queue.push.async { [weak dispatcher] in
                guard let dispatcher = dispatcher, let pkt = self.lastPacket, pkt.userId == userId,
                      dispatcher.shouldHandlePacket(pkt) else { return }
                dispatcher.lastPacket = pkt
            }
        }
        return dispatcher
    }
}

public final class PushDispatcher<T> {
    let userId: String
    let shouldCacheLast: Bool
    private(set) var filters: [(T) -> Bool] = []
    fileprivate var lastPacket: PushPacket<T>?
    fileprivate var listeners = Listeners<PushHandler<T>>()

    init(userId: String, shouldCacheLast: Bool) {
        self.userId = userId
        self.shouldCacheLast = shouldCacheLast
    }

    @discardableResult
    public func filter(_ predicate: @escaping (T) -> Bool) -> Self {
        Queue.push.async { [weak self] in
            self?.filters.append(predicate)
        }
        return self
    }

    /// 会监听到observer释放
    @discardableResult
    public func addObserver(_ observer: AnyObject, handleCacheIfExists: Bool = true,
                            willHandle: ((T) -> Void)? = nil, didHandle: ((T) -> Void)? = nil,
                            handler: ((T) -> Void)?) -> AnyObject {
        let obj = PushHandler(observer, willHandle: willHandle, didHandle: didHandle, handler: handler)
        obj.dispatcher = self
        self._addObserver(obj, handleCacheIfExists: handleCacheIfExists)
        return obj
    }

    public func removeObserver(_ observer: AnyObject) {
        if let handler = observer as? PushHandler<T> {
            self._removeObserver(handler)
        } else {
            let id = ObjectIdentifier(observer)
            self.listeners.filter({ $0.id == id }).forEach {
                self._removeObserver($0)
            }
        }
    }

    public func ofType<Observer>(_ type: Observer.Type, willHandle: ((Observer, T) -> Void)? = nil,
                                 didHandle: ((Observer, T) -> Void)? = nil,
                                 handler: ((Observer, T) -> Void)?) -> TypedPushDispatcher<T, Observer> {
        TypedPushDispatcher(self, willHandle: willHandle, didHandle: didHandle, handler: handler)
    }

    public func cleanCache() {
        Queue.push.async { [weak self] in
            self?.lastPacket = nil
        }
    }

    func shouldHandleRawPacket(_ packet: RawPushPacket) -> Bool {
        self.userId == packet.userId && (self.shouldCacheLast || !self.listeners.isEmpty)
    }

    func shouldHandlePacket(_ packet: PushPacket<T>) -> Bool {
        filters.allSatisfy { $0(packet.message) }
    }

    func willHandlePushPacket(_ packet: PushPacket<T>) {
        if self.shouldCacheLast {
            self.lastPacket = packet
        }
        listeners.forEach { $0.willHandlePushPacket(packet) }
    }

    func handlePushPacket(_ packet: PushPacket<T>) {
        listeners.forEach { $0.handlePushPacket(packet) }
    }

    func didHandlePushPacket(_ packet: PushPacket<T>) {
        listeners.forEach { $0.didHandlePushPacket(packet) }
    }

    fileprivate func _addObserver(_ handler: PushHandler<T>, handleCacheIfExists: Bool) {
        self.listeners.addListener(handler)
        Queue.push.async { [weak self] in
            guard let owner = handler.owner else { return }
            var handlers = (objc_getAssociatedObject(owner, &PushAssociateKeys.pushHandlers) as? [ObjectIdentifier: Any]) ?? [:]
            handlers[ObjectIdentifier(handler)] = handler
            objc_setAssociatedObject(owner, &PushAssociateKeys.pushHandlers, handlers, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if let self = self, handleCacheIfExists, let pkt = self.lastPacket {
                handler.willHandlePushPacket(pkt)
                handler.handlePushPacket(pkt)
                handler.didHandlePushPacket(pkt)
            }
        }
    }

    fileprivate func _removeObserver(_ handler: PushHandler<T>) {
        self.listeners.removeListener(handler)
        Queue.push.async { [weak handler] in
            if let handler = handler, let owner = handler.owner,
               var handlers = objc_getAssociatedObject(owner, &PushAssociateKeys.pushHandlers) as? [ObjectIdentifier: Any],
               handlers.removeValue(forKey: ObjectIdentifier(handler)) != nil {
                objc_setAssociatedObject(owner, &PushAssociateKeys.pushHandlers, handlers, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
}

public final class TypedPushDispatcher<T, Observer> {
    let parent: PushDispatcher<T>
    let willHandle: ((Observer, T) -> Void)?
    let didHandle: ((Observer, T) -> Void)?
    let handler: ((Observer, T) -> Void)?
    init(_ parent: PushDispatcher<T>, willHandle: ((Observer, T) -> Void)?, didHandle: ((Observer, T) -> Void)?, handler: ((Observer, T) -> Void)?) {
        self.parent = parent
        self.willHandle = willHandle
        self.didHandle = didHandle
        self.handler = handler
    }

    /// 会监听到observer释放
    @discardableResult
    public func addObserver(_ observer: AnyObject, handleCacheIfExists: Bool = true,
                            willHandle: ((T) -> Void)? = nil, didHandle: ((T) -> Void)? = nil,
                            handler: ((T) -> Void)?) -> AnyObject {
        let obj = PushHandler(observer, willHandle: willHandle, didHandle: didHandle, handler: handler)
        obj.dispatcher = self
        self.parent._addObserver(obj, handleCacheIfExists: handleCacheIfExists)
        return obj
    }

    public func addObserver(_ observer: Observer, handleCacheIfExists: Bool = true) {
        let observer = observer as AnyObject
        addObserver(observer, handleCacheIfExists: handleCacheIfExists, willHandle: { [weak self, weak observer] in
            if let handler = self?.willHandle, let obj = observer as? Observer {
                handler(obj, $0)
            }
        }, didHandle: { [weak self, weak observer] in
            if let handler = self?.didHandle, let obj = observer as? Observer {
                handler(obj, $0)
            }
        }, handler: {[weak self, weak observer] in
            if let handler = self?.handler, let obj = observer as? Observer {
                handler(obj, $0)
            }
        })
    }

    public func removeObserver(_ observer: AnyObject) {
        parent.removeObserver(observer)
    }

    public func cleanCache() {
        parent.cleanCache()
    }
}

private class PushHandler<T> {
    let id: ObjectIdentifier
    /// hold一下dispatcher，不然可能就释放了
    fileprivate var dispatcher: AnyObject?
    private(set) weak var owner: AnyObject?
    private let handler: ((T) -> Void)?
    private let willHandle: ((T) -> Void)?
    private let didHandle: ((T) -> Void)?
    init(_ owner: AnyObject, willHandle: ((T) -> Void)?, didHandle: ((T) -> Void)?, handler: ((T) -> Void)?) {
        self.id = ObjectIdentifier(owner)
        self.owner = owner
        self.willHandle = willHandle
        self.didHandle = didHandle
        self.handler = handler
    }

    func willHandlePushPacket(_ packet: PushPacket<T>) {
        willHandle?(packet.message)
    }

    func handlePushPacket(_ packet: PushPacket<T>) {
        handler?(packet.message)
    }

    func didHandlePushPacket(_ packet: PushPacket<T>) {
        didHandle?(packet.message)
    }
}

private struct PushAssociateKeys {
    static var pushHandlers: UInt8 = 0
}
