//
//  LarkUIKit+Extension.swift
//  LarkUIKit
//
//  Created by Yuguo on 2017/12/11.
//  Copyright © 2017年 liuwanlin. All rights reserved.
//

import Foundation
public final class LarkUIKitExtension<BaseType> {
    public var base: BaseType
    public init(_ base: BaseType) {
        self.base = base
    }
}

// swiftlint:disable identifier_name
public protocol LarkUIKitExtensionCompatible {
    associatedtype LarkUIKitCompatibleType
    
    var lu: LarkUIKitCompatibleType { get }
    static var lu: LarkUIKitCompatibleType.Type { get }
}

public extension LarkUIKitExtensionCompatible {
    var lu: LarkUIKitExtension<Self> {
        return LarkUIKitExtension(self)
    }

    static var lu: LarkUIKitExtension<Self>.Type {
        return LarkUIKitExtension.self
    }
}

// swiftlint:enable identifier_name
