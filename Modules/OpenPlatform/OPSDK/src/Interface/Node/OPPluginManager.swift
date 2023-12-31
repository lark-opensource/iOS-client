//
//  OPPluginManager.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/6.
//

import Foundation

/// 插件管理协议，包括注册和反注册等
@objc public protocol OPPluginManagerProtocol: NSObjectProtocol {
    
    /// 注册一个插件
    /// - Parameter plugin: 插件
    func registerPlugin(plugin: OPPluginProtocol)
    
    /// 反注册指定插件
    /// - Parameter plugin: 插件
    func unregisterPlugin(plugin: OPPluginProtocol)

    /// 注册一组插件
    /// - Parameter plugins: 插件组
    func registerPlugins(plugins: [OPPluginProtocol])

    /// 反注册所有插件
    func unregisterAllPlugins()
    
}


/// OPPluginManagerProtocol 的一个默认实现
@objcMembers class OPPluginManager: NSObject, OPPluginManagerProtocol {
    
    private var plugins: [String: [OPPluginProtocol]] = [:]
    func registerPlugin(plugin: OPPluginProtocol) {
        objc_sync_enter(self)
        plugin.filters.forEach { (eventName) in
            if var eventPlugins = plugins[eventName] {
                // 如果之前应添加该Plugin，应当先移除，避免同一个Plugin被添加两次
                if let index = eventPlugins.firstIndex { (_pugin) -> Bool in
                    plugin.isEqual(_pugin)
                } {
                    eventPlugins.remove(at: index)
                }
                eventPlugins.append(plugin)
            } else {
                plugins[eventName] = [plugin]
            }
        }
        objc_sync_exit(self)
    }
    
    func unregisterPlugin(plugin: OPPluginProtocol) {
        objc_sync_enter(self)
        plugins.forEach { (eventName, eventPlugins) in
            var eventPlugins = eventPlugins
            if let index = eventPlugins.firstIndex { (_pugin) -> Bool in
                plugin.isEqual(_pugin)
            } {
                eventPlugins.remove(at: index)
            }
        }
        objc_sync_exit(self)
    }

    func registerPlugins(plugins: [OPPluginProtocol]) {
        plugins.forEach { plugin in
            registerPlugin(plugin: plugin)
        }
    }

    func unregisterAllPlugins() {
        objc_sync_enter(self)
        plugins.removeAll()
        objc_sync_exit(self)
    }
}

/// 实现 OPEventTargetProtocol 协议，支持事件拦截和处理
extension OPPluginManager: OPEventTargetProtocol {
    
    func interceptEvent(event: OPEvent, callback: OPEventCallback) -> Bool {
        guard let eventPlugins = plugins[event.eventName] else {
            return false
        }
        // 逆序遍历，后添加的Plugin优先级更高
        for plugin in eventPlugins.reversed() {
            if plugin.interceptEvent(event: event, callback: callback) {
                return true
            }
        }
        return false
    }
    
    func handleEvent(event: OPEvent, callback: OPEventCallback) -> Bool {
        guard let eventPlugins = plugins[event.eventName] else {
            return false
        }
        // 逆序遍历，后添加的Plugin优先级更高
        for plugin in eventPlugins.reversed() {
            if plugin.handleEvent(event: event, callback: callback) {
                return true
            }
        }
        return false
    }
}
