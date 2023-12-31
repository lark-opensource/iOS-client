//
//  MenuPluginContext.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/3/2.
//

import Foundation

@objc
/// 菜单插件的上下文，此上下文和插件上下文一起用于初始化插件
public final class MenuPluginContext: NSObject {
    /// 此插件的ID
    public var pluginID: String {
        self.plugin.pluginID
    }

    /// 此插件支持的菜单上下文
    public var enableMenuContexts: [MenuContext.Type] {
        self.plugin.enableMenuContexts
    }

    /// 插件的类型
    public private(set) var plugin: MenuPlugin.Type

    /// 插件初始化时的上下文信息
    public private(set) var parameters: [String: Any]

    /// 初始化插件上下文
    /// - Parameters:
    ///   - plugin: 插件的类型
    ///   - parameters: 插件初始化时的必要上下文
    @objc
    public init(plugin: MenuPlugin.Type, parameters: [String: Any]) {
        self.plugin = plugin
        self.parameters = parameters
        super.init()
    }

    /// 初始化插件上下文
    /// - Parameters:
    ///   - plugin: 插件的类型
    @objc
    public convenience init(plugin: MenuPlugin.Type) {
        self.init(plugin: plugin, parameters: [:])
    }
}
