//
//  MenuPanelPluginOperationHandler.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/3/30.
//

import Foundation

@objc
/// 控制菜单面板插件的能力
public protocol MenuPanelPluginOperationHandler {

    /// 需要删除的menuItem的pluginID数组
    func updateMenuItemsToBeRemoved(with disabled_menus: [String])

    /// 此操作会根据菜单上下文信息获取相关的插件,然后重置菜单内所有的插件
    /// - Parameters:
    ///   - menuContext: 菜单上下文
    /// - Note: 注意必须在主线程执行。如果你一不小心在其他线程执行，则不会被执行，会触发assert，
    ///         因此会发生一些其他奇怪的问题，责任需要自己承担
    ///         如果插件ID已存在，那么更新后，内部会生成新的插件实例，而不是在现有的插件实例基础上进行更新
    func makePlugins(with menuContext: MenuContext)

    /// 此操作会根据菜单上下文信息获取相关的插件,然后重置菜单内所有的插件,效果与上面的方法一致
    /// - Parameters:
    ///   - menuContext: 菜单上下文
    /// - Note: 注意必须在主线程执行。如果你一不小心在其他线程执行，则不会被执行，会触发assert，
    ///         因此会发生一些其他奇怪的问题，责任需要自己承担
    ///         如果插件ID已存在，那么更新后，内部会生成新的插件实例，而不是在现有的插件实例基础上进行更新
    func remakePlugins(with menuContext: MenuContext)
}
