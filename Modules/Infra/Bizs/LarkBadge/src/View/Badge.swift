//
//  Badge.swift
//  LarkBadge
//
//  Created by 康涛 on 2019/4/4.
//

import Foundation
import UIKit

/// This type provides an extension point for connivence methods in Badge.
public final class Badge<Base> {
    public let base: Base
    /// badge with path
    /// - Parameter base: base
    public init(_ base: Base) {
        self.base = base
    }
}

/// This type provides an extension point for connivence methods in Badge.
public final class UIBadge<Base> {
    /// base
    public let base: Base
    /// badge only with UI
    /// - Parameter base: base
    public init(_ base: Base) {
        self.base = base
    }
}

/// Represents a type which is compatible with Badge. You can use `badge` property to get a
/// value in the namespace of Badge.
public protocol BadgeCompatible { }

public extension BadgeCompatible {

    /// Gets a namespace holder for Badge compatible types.
    var badge: Badge<Self> {
        return Badge(self)
    }

    /// badge only with UI
    var uiBadge: UIBadge<Self> {
        return UIBadge(self)
    }
}

/// Add namespace
extension UIView: BadgeCompatible { }
extension UITabBarItem: BadgeCompatible { }
extension UIBarButtonItem: BadgeCompatible { }
