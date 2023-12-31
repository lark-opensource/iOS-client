//
//  Event.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/14.
//

import Foundation

public final class EventHandlerDisposable {
    private(set) var isDisposed: Bool = false

    public func dispose() {
        isDisposed = true
    }
}

public final class Event<T> {

    public typealias EventHandler = (T) -> Bool

    public init() { }

    private var eventHandlers = [EventHandler]()
    private var queue = DispatchQueue(label: "Event sync queue")

    public func update(data: T) {
        queue.sync {
            self.eventHandlers.removeAll(where: { $0(data) })

        }
    }

    public func addHander(handler: @escaping EventHandler) {
        queue.sync {
            eventHandlers.append(handler)
        }
    }

    @discardableResult
    public func addHandler<U: AnyObject>(target: U,
                                         handler: @escaping (U) -> (T) -> Void) -> EventHandlerDisposable {
        let disposable = EventHandlerDisposable()

        let wrapper: EventHandler = { [weak target] value in

            if let t = target {
                handler(t)(value)
                return disposable.isDisposed
            } else {
                return true
            }

        }
        queue.sync {
            eventHandlers.append(wrapper)
        }
        return disposable
    }
}
