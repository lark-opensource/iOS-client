//
//  VcExtension.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/3/17.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

public final class VCExtension<BaseType> {
    public var base: BaseType
    public init(_ base: BaseType) {
        self.base = base
    }
}

public protocol VCExtensionCompatible {
    associatedtype VcExtensionCompatibleType
    var vc: VcExtensionCompatibleType { get }
    static var vc: VcExtensionCompatibleType.Type { get }
}

public extension VCExtensionCompatible {
    var vc: VCExtension<Self> {
        return VCExtension(self)
    }

    static var vc: VCExtension<Self>.Type {
        return VCExtension.self
    }
}

extension UIViewController: VCExtensionCompatible {}
extension UIView: VCExtensionCompatible {}
extension CALayer: VCExtensionCompatible {}
