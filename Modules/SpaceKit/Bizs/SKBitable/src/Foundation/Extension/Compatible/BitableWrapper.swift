//
//  URL+Extension.swift
//  SKBitable
//
//  Created by X-MAN on 2023/12/20.
//

import Foundation

public struct BitableWrapper<Base> {

    public let base: Base

    fileprivate init(base: Base) {
        self.base = base
    }
}

/// Represents an object type that is compatible.
/// You can use `bitable` property to get a value in the namespace.
public protocol BitableCompatible {}

extension BitableCompatible {

    /// Gets a namespace holder for compatible types.
    public var bitable: BitableWrapper<Self> {
        get { BitableWrapper(base: self) }
        set {}
    }
}

/// Represents a value type that is compatible.
/// You can use `bitable` property to get a value in the namespace.
public protocol BitableCompatibleValue {}

extension BitableCompatibleValue {

    /// Gets a namespace holder for compatible types.
    public var bitable: BitableWrapper<Self> {
        get { BitableWrapper(base: self) }
        set {}
    }
}

