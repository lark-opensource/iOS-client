//
//  ImageWrapper.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/3/18.
//

import Foundation

/// Wrapper for ImageWrapper compatible types.
/// This type provides an extension point for convenience methods in ImageWrapper.
public struct ImageWrapper<Base> {

    public let base: Base

    fileprivate init(base: Base) {
        self.base = base
    }
}

/// Represents an object type that is compatible.
/// You can use `bt` property to get a value in the namespace.
public protocol ImageCompatible: AnyObject {}

extension ImageCompatible {

    /// Gets a namespace holder for compatible types.
    public var bt: ImageWrapper<Self> {
        get { ImageWrapper(base: self) }
        set {}
    }
}

/// Represents a value type that is compatible.
/// You can use `bt` property to get a value in the namespace.
public protocol ImageCompatibleValue {}

extension ImageCompatibleValue {

    /// Gets a namespace holder for compatible types.
    public var bt: ImageWrapper<Self> {
        get { ImageWrapper(base: self) }
        set {}
    }
}
