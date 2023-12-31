//
//  MenuPanelVisibleOperationHandler.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/3/30.
//

import Foundation

@objc
/// 控制菜单面板是否可见的能力
public protocol MenuPanelVisibleOperationHandler {
    /// 隐藏菜单面板
    /// - Parameters:
    ///   - animation: 是否进行动画
    ///   - complete: 隐藏完成之后的回调
    /// - Note: 注意必须在主线程执行。如果你一不小心在其他线程执行，则不会被执行，会触发assert，
    ///         因此会发生一些其他奇怪的问题，责任需要自己承担
    func hide(animation: Bool, complete: (() -> Void)?)

    /// 显示菜单面板
    /// - Parameters:
    ///   - sourceView: 点击哪个视图弹出面板
    ///   - parentPath: 父视图的badge路径
    ///   - models: 选项数据模型
    ///   - additionView: 附加视图
    ///   - animation: 是否进行动画
    ///   - complete: 显示之后的回调
    /// - Note: 注意必须在主线程执行。如果你一不小心在其他线程执行，则不会被执行，会触发assert，
    ///         因此会发生一些其他奇怪的问题，责任需要自己承担
    func show(from sourceView: MenuPanelSourceViewModel, parentPath: MenuBadgePath, animation: Bool, complete: (() -> Void)?)
}
