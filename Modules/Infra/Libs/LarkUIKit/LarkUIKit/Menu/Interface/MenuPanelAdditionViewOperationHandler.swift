//
//  MenuPanelAdditionViewOperationHandler.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/3/30.
//

import Foundation

@objc
/// 控制菜单面板附加视图的能力
public protocol MenuPanelAdditionViewOperationHandler {
    /// 更新菜单的头部
    /// - Parameter view: 菜单的头部视图
    /// - Note: 注意必须在主线程执行。如果你一不小心在其他线程执行，则不会被执行，会触发assert，
    ///         因此会发生一些其他奇怪的问题，责任需要自己承担。
    func updatePanelHeader(for view: MenuAdditionView?)

    /// 更新菜单的底部
    /// - Parameter view: 菜单的底部视图
    /// - Note: 注意必须在主线程执行。如果你一不小心在其他线程执行，则不会被执行，会触发assert，
    ///         因此会发生一些其他奇怪的问题，责任需要自己承担
    func updatePanelFooter(for view: MenuAdditionView?)
}
