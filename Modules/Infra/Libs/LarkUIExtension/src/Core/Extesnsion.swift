//
//  Extesnsion.swift
//  LarkUIExtensionWrapper
//
//  Created by 李晨 on 2020/3/10.
//

import Foundation

public final class LarkUIExtensionWrapper<BaseType> {
    public var base: BaseType
    public init(_ base: BaseType) {
        self.base = base
    }
}

public protocol LarkUIExtensionCompatible {
    associatedtype LarkUICompatibleType
    var ue: LarkUICompatibleType { get }
    static var ue: LarkUICompatibleType.Type { get }
}

public extension LarkUIExtensionCompatible {
    var ue: LarkUIExtensionWrapper<Self> {
        return LarkUIExtensionWrapper(self)
    }

    static var ue: LarkUIExtensionWrapper<Self>.Type {
        return LarkUIExtensionWrapper.self
    }
}

extension NSObject: LarkUIExtensionCompatible {}
