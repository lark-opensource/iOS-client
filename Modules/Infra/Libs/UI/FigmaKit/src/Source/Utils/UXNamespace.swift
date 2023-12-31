//
//  UXNamespace.swift
//  FigmaKit
//
//  Created by Hayden Wang on 2021/9/4.
//

import UIKit
import Foundation

/// UX namespace extension
public final class UXExtension<BaseType> {

    /// The base type instance that the extension rely on.
    public var base: BaseType

    /// Initializer.
    public init(_ base: BaseType) {
        self.base = base
    }
}

/// UXExtension protocol
public protocol UXExtensible {

    /// The 'ux' extension type.
    associatedtype UXExtensionType

    /// The 'ux' namespace.
    var ux: UXExtensionType { get }

    /// The 'ux' namespace.
    static var ux: UXExtensionType.Type { get }
}

public extension UXExtensible {

    /// The 'ux' namespace.
    var ux: UXExtension<Self> {
        return UXExtension(self)
    }

    /// The 'ux' namespace.
    static var ux: UXExtension<Self>.Type {
        return UXExtension.self
    }
}

extension CALayer: UXExtensible {}
