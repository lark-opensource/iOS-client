//
//  WorkplaceCompatible.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/7/7.
//

import Foundation

/// 工作台类型扩展入口，隔离单独命名空间
///
/// 需要为某些类型添加方法扩展时，避免相关接口与类型本身混合在一起，通过 wp 命名空间隔离。
///
/// 以系统类型扩展为例，扩展方式如下:
/// ```
/// extension String: WorkplaceCompatible {}
/// extension WorkplaceExtension where BaseType == String {
///     func base64() -> String {
///         return base.xxx
///     }
/// }
/// ```
/// 使用:
/// ```
/// let value = "hello"
/// print(value.wp.base64())
/// ```
protocol WorkplaceCompatible {
    associatedtype WorkplaceExtensionType

    /// 扩展的隔离命名空间
    var wp: WorkplaceExtensionType { get }
}

extension WorkplaceCompatible {
    var wp: WorkplaceExtension<Self> {
        return WorkplaceExtension(self)
    }
}

/// 工作台类型扩展容器
struct WorkplaceExtension<BaseType> {
    private(set) var base: BaseType

    init(_ base: BaseType) {
        self.base = base
    }
}
