//
//  LIImageWrapper.swift
//  LarkIcon
//
//  Created by huangzhikai on 2023/12/13.
//

import Foundation
import RxSwift

/// Wrapper for ImageWrapper compatible types.
/// This type provides an extension point for convenience methods in ImageWrapper.
public class LIImageWrapper<Base> {
    
    public let base: Base
    
    fileprivate init(base: Base) {
        self.base = base
    }
}

/// Represents an object type that is compatible.
/// You can use `di` property to get a value in the namespace.
public protocol LIImageCompatible: AnyObject {}

public extension LIImageCompatible {
    
    /// Gets a namespace holder for compatible types.
    var li: LIImageWrapper<Self> {
        get { LIImageWrapper(base: self) }
        set {}
    }
}

extension UIImageView: LIImageCompatible {}


private enum AssociativeKey {
    
    static var reuseBagKey = "LarkIcon.AssociativeKey.reuseBagKey"
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
