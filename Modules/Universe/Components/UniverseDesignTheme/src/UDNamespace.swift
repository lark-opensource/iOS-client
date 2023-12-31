//
//  UDTheme+Namespace.swift
//  UniverseDesignTheme
//
//  Created by Hayden on 2021/4/6.
//

import Foundation
import UIKit

/// UDComponents Extension
public final class UDComponentsExtension<BaseType> {

    /// The base type instance that the extension rely on.
    public var base: BaseType

    /// Initializer.
    public init(_ base: BaseType) {
        self.base = base
    }
}

/// UDComponents ExtensionCompatible
public protocol UDComponentsExtensible {

    /// UDComponentsCompatible Type
    associatedtype UDComponentsExtensionType

    /// UDComponents Extension
    var ud: UDComponentsExtensionType { get }

    /// UDComponents Extension Type
    static var ud: UDComponentsExtensionType.Type { get }
}

public extension UDComponentsExtensible {

    /// UDComponents Extension
    var ud: UDComponentsExtension<Self> {
        return UDComponentsExtension(self)
    }

    /// UDComponents Extension Type
    static var ud: UDComponentsExtension<Self>.Type {
        return UDComponentsExtension.self
    }
}

extension CALayer: UDComponentsExtensible {}
extension UIView: UDComponentsExtensible {}
extension UIColor: UDComponentsExtensible {}
extension UIImage: UDComponentsExtensible {}
extension UIFont: UDComponentsExtensible {}
//extension NSObject: UDComponentsExtensible {}
