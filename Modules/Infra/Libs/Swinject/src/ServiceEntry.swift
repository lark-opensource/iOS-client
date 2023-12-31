//
//  ServiceEntry.swift
//  SwinjectTest
//
//  Created by CharlieSu on 4/29/20.
//  Copyright © 2020 Lark. All rights reserved.
//

import Foundation
import EEAtomic

// Type alias to expect a closure.
typealias FunctionType = Any

/// a generic erase type for ServiceEntry
public protocol ServiceEntryProtocol: AnyObject {
    var objectScope: ObjectScope { get }
    /// reset the shared storage on the service entry
    func reset()
}

/// The `ServiceEntry<Service>` class represents an entry of a registered service type.
/// As a returned instance from a `register` method of a `Container`, some configurations can be added.
public final class ServiceEntry<Service>: ServiceEntryProtocol {
    // let serviceType: Any.Type
    // let argumentsType: Any.Type
    let factory: FunctionType
    public var objectScope = ObjectScope.default {
        didSet {
            objectScope.attach(to: self)
        }
    }

    // optional storage for permanent storage. var only can set when init
    public var storage: AtomicObject<Service?>?

    init(serviceType: Service.Type,
         argumentsType: Any.Type,
         factory: FunctionType) {
        // self.serviceType = serviceType
        // self.argumentsType = argumentsType
        self.factory = factory
    }

    public func reset() {
        objectScope.reset(entry: self)
    }

    /// Specifies the object scope to resolve the service.
    ///
    /// - Parameter scope: Different type of ObjectObject
    ///
    /// - Returns: `self` to add another configuration fluently.
    @discardableResult
    public func inObjectScope(_ objectScope: ObjectScope) -> Self {
        self.objectScope = objectScope
        return self
    }
}
