//
//  RTExtension.swift
//  RichTextEditor
//
//  Created by chenhuaguan on 2020/6/30.
//

import Foundation

final class RTExtension<BaseType> {
    var base: BaseType
    init(_ base: BaseType) {
        self.base = base
    }
}

protocol RTExtensionCompatible {
    associatedtype RTCompatibleType
    var rt: RTCompatibleType { get }
    static var rt: RTCompatibleType.Type { get }
}

extension RTExtensionCompatible {
    var rt: RTExtension<Self> {
        return RTExtension(self)
    }
    static var rt: RTExtension<Self>.Type {
        return RTExtension.self
    }
}
