//
//  MenuPlugin.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/3/1.
//

import Foundation

@objc
/// 插件的必要信息
public protocol MenuPlugin {

    /// 菜单将显示时调用的方法
    /// 注意这个方法不一定会被调用，当菜单面板已经显示后，再更新插件，新的插件不会调用这个方法
    /// - Parameter handler: 插件的操作句柄
    @objc optional func menuWillShow(handler: MenuPluginOperationHandler)

    /// 菜单已经显示时调用的方法
    /// - Parameter handler: 插件的操作句柄
    @objc optional func menuDidShow(handler: MenuPluginOperationHandler)

    /// 菜单将结束显示时调用的方法
    /// - Parameter handler: 插件的操作句柄
    @objc optional func menuWillHide(handler: MenuPluginOperationHandler)

    /// 菜单已经结束显示时调用的方法
    /// - Parameter handler: 插件的操作句柄
    @objc optional func menuDidHide(handler: MenuPluginOperationHandler)

    /// 菜单已经销毁时调用的方法
    @objc optional func menuDealloc()

    /// 一般用于在菜单显示前让插件开始工作，插件的一些耗时的准备工作， 插件的一些耗时的准备工作
    /// 此方法会在Handler 的updatePlugins方法调用时，根据传入的上下文寻找到所需的插件，然后执行它的初始化方法
    /// 一个插件在它的一生中只会执行一次这个方法，即初始化完成后立即执行
    /// 这个方法还有一个好处，如果菜单面板已经显示，
    /// 但是新加入了插件，那么会触发pluginDidLoad而不会触发menuWillShow，于是这个时机很适合去更新面板
    /// - Parameter handler: 插件的操作句柄
    @objc optional func pluginDidLoad(handler: MenuPluginOperationHandler)

    /// 初始化插件
    /// - Parameters:
    ///   - menuContext: 菜单上下文
    ///   - pluginContext: 插件的上下文
    init?(menuContext: MenuContext, pluginContext: MenuPluginContext)

    /// 插件的插件ID
    static var pluginID: String {get}

    /// 插件支持的菜单上下文
    static var enableMenuContexts: [MenuContext.Type] {get}
}
