//
//  MenuActionDelegate.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/2/1.
//

import Foundation
import UIKit

/// 菜单点击事件的代理
protocol MenuActionDelegate: AnyObject {
    /// 在执行选项行为之前的前置操作
    /// - Parameters:
    ///   - autoClose: 是否应该关闭菜单
    ///   - animation: 关闭菜单是否动画
    ///   - action: 点击事件之后需要执行的行为
    func actionMenu(for identifier: String?, autoClose: Bool, animation: Bool, action: (() -> Void)?)
}
