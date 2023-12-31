//
//  AlternateAnimatorViewWrapper.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/2/23.
//

import UIKit

/// 用于将视图弱引用持有的一个包装器
final class AlternateAnimatorViewWrapper {
    /// 需要引用的UIView
    weak var view: UIView?

    /// 初始化包装器
    /// - Parameter view: 需要引用的UIView
    init(view: UIView) {
        self.view = view
    }
}
