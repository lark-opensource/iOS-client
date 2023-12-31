//
//  UdStyleExtension.swift
//  Pods-UniverseDesignStyleDev
//
//  Created by 强淑婷 on 2020/8/11.
//

import Foundation

/// Style的Extension
public final class UDStyleExtension<BaseType> {
    var base: BaseType
    init(_ base: BaseType) {
        self.base = base
    }
}
/// Extension兼容协议
public protocol UDStyleExtensionCompatible {
    /// 关联类型
    associatedtype UDStyleCompatibleType
    /// StyleExtension的后缀
    var ud: UDStyleCompatibleType { get }
    /// StyleExtension的后缀Type
    static var ud: UDStyleCompatibleType.Type { get }
}

public extension UDStyleExtensionCompatible {
    /// StyleExtension的后缀
    var ud: UDStyleExtension<Self> {
        return UDStyleExtension(self)
    }
    /// StyleExtension的后缀Type
    static var ud: UDStyleExtension<Self>.Type {
        return UDStyleExtension.self
    }
}
