//
//  MenuPluginAssembly.swift
//  EEMicroAppSDK
//
//  Created by 刘洋 on 2021/3/16.
//

import Foundation
import LarkUIKit
import OPGadget
import TTMicroApp

@objc
/// 菜单插件收集器，负责注入小程序插件
public final class MenuPluginAssembly: NSObject {
    /// 往菜单中注入小程序菜单插件
    @objc
    public static func injectAppMenuPlugin() {
        /// 注册小程序debug插件
        let appDebugContext = MenuPluginContext(
            plugin: AppDebugMenuPlugin.self
        )
        MenuPluginPool.registerPlugin(pluginContext: appDebugContext)

        /// 注册小程序LarkDebug插件
        let appLarkDebugContext = MenuPluginContext(
            plugin: AppLarkDebugMenuPlugin.self
        )
        MenuPluginPool.registerPlugin(pluginContext: appLarkDebugContext)

        /// 注册重新进入小程序插件
        let gadgetReloadContext = MenuPluginContext(
            plugin: GadgetReloadMenuPlugin.self
        )
        MenuPluginPool.registerPlugin(pluginContext: gadgetReloadContext)

        /// 注册小程序设置插件
        let appSettingContext = MenuPluginContext(
            plugin: AppSettingMenuPlugin.self
        )
        MenuPluginPool.registerPlugin(pluginContext: appSettingContext)

        /// 注册小程序返回主页插件
        let appHomeContext = MenuPluginContext(
            plugin: AppHomeMenuPlugin.self
        )
        MenuPluginPool.registerPlugin(pluginContext: appHomeContext)
        
        /// 清理小程序缓存插件
        let gadgetCacheClearContext = MenuPluginContext(
            plugin: GadgetCacheClearPlugin.self
        )
        MenuPluginPool.registerPlugin(pluginContext: gadgetCacheClearContext)

        /// 注册小程序菜单头插件
        let appCompactHeaderContext = MenuPluginContext(
            plugin: AppMenuCompactHeaderPlugin.self
        )
        MenuPluginPool.registerPlugin(pluginContext: appCompactHeaderContext)

        let appRegularHeaderContext = MenuPluginContext(
            plugin: AppMenuRegularHeaderPlugin.self
        )
        MenuPluginPool.registerPlugin(pluginContext: appRegularHeaderContext)
    }
}
