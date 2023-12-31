//
//  AsyncResult.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/9/28.
//

import Foundation

public final class AsyncResult: Resource {
    public typealias ObserverBlock = (AsyncResult) -> Void

    private var _identifier: String?
    public var identifier: String? {
        get {
            return resource?.identifier ?? _identifier
        }
        set {
            _identifier = newValue
            resource?.identifier = newValue
        }
    }

    public private(set) var resource: Resource? {
        didSet {
            _identifier = resource?.identifier
        }
    }
    public private(set) var error: Error?

    private var observers: [ObserverBlock] = []

    init() {}

    /// Set the resource when the resource is ready
    ///
    /// - Parameter resource: resource
    func set(resource: Resource?) {
        self.resource = resource

        self.observers.forEach { (block) in
            block(self)
        }

        self.observers = []
    }

    /// Set the resource when the resource is ready
    ///
    /// - Parameter resource: resource
    func set(error: Error?) {
        self.error = error

        self.observers.forEach { (block) in
            block(self)
        }

        self.observers = []
    }

    /// Add observer for the
    ///
    /// - Parameter observer: observer block
    public func add(observer: @escaping ObserverBlock) {
        if resource != nil || error != nil {
            observer(self)
        } else {
            self.observers.append(observer)
        }
    }

    /// Release
    func release() {
        self.observers = []
    }
}
