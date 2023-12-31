//
//  ImageWrapper.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/6/13.
//

import Foundation
import RxSwift

/// Wrapper for ImageWrapper compatible types.
/// This type provides an extension point for convenience methods in ImageWrapper.
public class DIImageWrapper<Base> {

    public let base: Base

    fileprivate init(base: Base) {
        self.base = base
    }
}

/// Represents an object type that is compatible.
/// You can use `di` property to get a value in the namespace.
public protocol DIImageCompatible: AnyObject {}

public extension DIImageCompatible {

    /// Gets a namespace holder for compatible types.
    var di: DIImageWrapper<Self> {
        get { DIImageWrapper(base: self) }
        set {}
    }
}

extension UIImageView: DIImageCompatible {}


private enum AssociativeKey {

    static var reuseBagKey = "AssociativeKey.reuseBagKey"
}

extension UIImageView {
    /// 用来解决复用的标志
    internal var reuseBag: DisposeBag? {
        get {
            objc_getAssociatedObject(self, &AssociativeKey.reuseBagKey) as? DisposeBag
        }
        set {
            objc_setAssociatedObject(self, &AssociativeKey.reuseBagKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
