//
//  SKFoundation.swift
//  SKFoundation
//
//  Created by lijuyou on 2020/6/2.
//  


import Foundation

//实现Date.sk.xxx之类的扩展
public struct SKExtension<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

public protocol SKExtensionCompatible {
    associatedtype SKExtensionCompatibleType
    var sk: SKExtensionCompatibleType { get }
    static var sk: SKExtensionCompatibleType.Type { get }
}

public extension SKExtensionCompatible {
    var sk: SKExtension<Self> { SKExtension(self) }

    static var sk: SKExtension<Self>.Type { SKExtension.self }
}

//实现调用protocol反射出来对象的static方法
public protocol SKTypeAccessible: AnyObject {
    func type() -> Self.Type
}

extension SKTypeAccessible {
    public func type() -> Self.Type {
        return Swift.type(of: self)
    }
}
