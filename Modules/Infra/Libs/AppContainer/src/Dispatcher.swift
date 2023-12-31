//
//  Dispatcher.swift
//  Pods-AppContainerDev
//
//  Created by liuwanlin on 2018/11/15.
//

import Foundation

public protocol Message {
    static var name: String { get }
    associatedtype HandleReturnType = Void
}

public protocol Observer: AnyObject {
    static var config: Config { get }
}

fileprivate extension Message {
    static var key: String {
        return String(UInt(bitPattern: ObjectIdentifier(type(of: self))))
    }
}

public final class Dispatcher {
    private typealias Handler<M: Message> = (Observer, M) -> M.HandleReturnType
    private struct ObserverItem<M: Message> {
            weak var observer: Observer?
            let handler: Handler<M>
        }

    private var observerItemDic: [String: [Any]] = [:]

    /// Dispatcher block state
    /// if Dispatcher is blocking，will cache all application event
    private(set) var blocking: Bool = false

    var dispatcherBlocking: Bool = false {
        didSet {
            self.blocking = dispatcherBlocking
            guard oldValue == true, dispatcherBlocking == false else { return }
            // 执行缓存的
            self.handleLaunchBlockIfNeeded()
        }
    }

    func handleLaunchBlockIfNeeded() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.cache.forEach { (cacheBlock) in
                cacheBlock()
            }
            self.cache.removeAll()
        }
    }

    /// application event cache
    private var cache: [() -> Void] = []

    @discardableResult
    func send<M: Message>(message: M) -> [M.HandleReturnType] {
        if blocking {
            DispatchQueue.main.async { [weak self] in
                self?.cache.append({ [weak self] in
                    self?.sendEvent(message: message)
                })
            }
            return []
        }
        return sendEvent(message: message)
    }

    @discardableResult
    private func sendEvent<M: Message>(message: M) -> [M.HandleReturnType] {
        let items = getMessageObservers(message: type(of: message))
        return items.compactMap { (observerItem) -> M.HandleReturnType? in
            if let observer = observerItem.observer {
                let observerName = type(of: observer).config.name
                let messageName = type(of: message).name
                let eventName = messageName + "-" + observerName
                let result: M.HandleReturnType
                if messageName == "KeyboardChange" {
                    result = observerItem.handler(observer, message)
                } else {
                    let id = TimeLogger.shared.logBegin(eventName: eventName)
                    result = observerItem.handler(observer, message)
                    TimeLogger.shared.logEnd(identityObject: id, eventName: eventName)
                }
                return result
            } else {
                return nil
            }
        }
    }

    public func add<M: Message>(observer: Observer, handler: @escaping (Observer, M) -> M.HandleReturnType) {
        let wrappedHandler: Handler<M> = { observer, message in
            handler(observer, message)
        }
        let item = ObserverItem(observer: observer, handler: wrappedHandler)
        setMessageObservers(observerItem: item)
    }

    private func setMessageObservers<M: Message>(observerItem: ObserverItem<M>) {
        var items = observerItemDic[M.self.key] ?? []
        items.append(observerItem)
        observerItemDic[M.self.key] = items
    }

    private func getMessageObservers<M: Message>(message: M.Type) -> [ObserverItem<M>] {
        let items = observerItemDic[M.self.key] ?? []
        return items as! [ObserverItem<M>]
    }
}
