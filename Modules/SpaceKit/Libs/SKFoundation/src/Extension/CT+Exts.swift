//
//  CT+Exts.swift
//  Bitable
//
//  Created by vvlong on 2018/9/16.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import UIKit
import ESPullToRefresh

public final class CTExtension<BaseType> {
    var base: BaseType
    init(_ base: BaseType) {
        self.base = base
    }
}

public protocol CTExtensionCompatible {
    associatedtype CTCompatibleType
    var ct: CTCompatibleType { get }
    static var ct: CTCompatibleType.Type { get }
}

public extension CTExtensionCompatible {
    var ct: CTExtension<Self> {
        return CTExtension(self)
    }
    static var ct: CTExtension<Self>.Type {
        return CTExtension.self
    }
}

public protocol CTExtensionsProvider: AnyObject {
    associatedtype CompatibleType
    var ct: CompatibleType { get }
}

extension CTExtensionsProvider {
    /// A proxy which hosts reactive extensions for `self`.
    public var ct: CT<Self> {
        return CT(self)
    }
}

public struct CT<Base> {
    public let base: Base
    
    // Construct a proxy.
    //
    // - parameters:
    //   - base: The object to be proxied.
    fileprivate init(_ base: Base) {
        self.base = base
    }
}

// MARK: 在Lark中编译报错，需要实现ct: NSObject
extension UIScrollView: CTExtensionsProvider {
    public var ct: ES<UIScrollView> {
        return self.es
    }
}
