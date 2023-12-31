//
//  AlternateAnimatorDelegate.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/2/23.
//

import Foundation
import UIKit

@objc
/// 动画器事件的代理
public protocol AlternateAnimatorDelegate {
    /// 动画器将开始动画
    /// - Parameter view: 动画作用于的UIView
    func animationWillStart(for view: UIView)

    /// 动画器将已经结束动画
    /// - Parameter view: 动画作用于的UIView
    func animationDidEnd(for view: UIView)

    /// 动画器动画时已经将一个动画元素添加至作用于的目标UIView上
    /// - Parameters:
    ///   - targetView: 动画作用于的UIView
    ///   - subview: 被添加的动画元素UIView
    func animationDidAddSubView(for targetView: UIView, subview: UIView)

    /// 动画器动画时已经将一个动画元素从作用于的目标UIView上移除
    /// - Parameters:
    ///   - targetView: 动画作用于的UIView
    ///   - subview: 被移除的动画元素UIView
    func animationDidRemoveSubView(for targetView: UIView, subview: UIView)
}
