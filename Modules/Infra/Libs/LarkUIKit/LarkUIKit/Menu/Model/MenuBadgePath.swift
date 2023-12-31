//
//  MenuBadgePath.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/3/25.
//

import Foundation
import LarkBadge

/// 对Path结构的封装，为了解决OC不支持结构体类型的问题
/// MenuBadgePath.Path类型为何会存在，因为在Xcode 12编译的时候，如果MenuBadgePath类中将LarkBadge.Path作为存储属性
/// 这个属性即使没有暴露给OC，虽然能通过编译阶段，但是链接器进行链接的时候，就会报错，原因未知，因为自己写一个结构体作为存储属性
/// 一样的条件，链接器可以正常链接，原因应该出在LarkBadge.Path这个结构体中。
/// 要么就是链接器存在bug，要么就是LarkBadge.Path这个结构体触发了Xcode的某种异常
/// 在这里采用绕开的方式，将LarkBadge.Path作为存储属性放置在MenuBadgePath.Path中，然后
/// MenuBadgePath.Path作为存储属性放在MenuBadgePath中，即可避免此问题
/// 如果升级到XCode 13可以验证此bug是否消失
public final class MenuBadgePath: NSObject {

    /// Badge路径
    var path: LarkBadge.Path {
        badgePath.path
    }

    private let badgePath: MenuBadgePath.Path

    /// 初始化路径
    /// - Parameter path: 字符串表示的路径
    @objc
    public init(path: String) {
        self.badgePath = .init(path: path)
        super.init()
    }

    /// 初始化路径
    /// - Parameter path: 路径
    public init(path: LarkBadge.Path) {
        self.badgePath = .init(path: path)
        super.init()
    }
}

extension MenuBadgePath {
    /// Path 的类型
    private final class Path {

        var path: LarkBadge.Path

        public init(path: String) {
            self.path = LarkBadge.Path.init().raw(path)
        }

        /// 初始化路径
        /// - Parameter path: 路径
        public init(path: LarkBadge.Path) {
            self.path = path
        }
    }
}
