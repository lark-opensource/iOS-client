//
//  MenuPluginPool.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/3/1.
//

import Foundation

@objc
/// 菜单插件的资源池
public final class MenuPluginPool: NSObject {
    /// 插件上下文的存储，以插件的ID作为key存储
    private static var plugins: [String: MenuPluginContext] = [:]

    /// 用于控制多线程写入读取存储的信号量
    private static let rwSignal = DispatchSemaphore(value: 1)

    /// 将插件上下文注册到资源池
    /// - Parameter pluginContext: 插件上下文
    public static func registerPlugin(pluginContext: MenuPluginContext) {
        Self.rwSignal.wait()
        Self.plugins[pluginContext.pluginID] = pluginContext
        Self.rwSignal.signal()
    }

    /// 根据插件上下文获取插件
    /// - Parameter menuContexts: 菜单上下文及其对应的插件ID
    /// - Returns: 插件
    public static func makePlugins(for menuContexts: [String: MenuContext]) -> [MenuPlugin] {
        Self.rwSignal.wait()
        let pluginContexts = menuContexts.compactMap {
            Self.plugins[$0.key]
        }
        Self.rwSignal.signal()
        var result: [MenuPlugin] = []
        for pluginContext in pluginContexts {
            guard let menuContext = menuContexts[pluginContext.pluginID],
                  let plugin = pluginContext.plugin.init(menuContext: menuContext, pluginContext: pluginContext) else {
                continue
            }
            result.append(plugin)
        }
        return result
    }

    /// 根据菜单上下文获取插件
    /// - Parameters:
    ///   - menuContext: 当前的菜单上下文
    /// - Returns: 插件
    public static func makePlugins(for menuContext: MenuContext) -> [MenuPlugin] {
        Self.rwSignal.wait()
        /// 根据当前上下文信息提取出域内的支持此上下文的插件
        let domainPluginContexts = Self.plugins.map {
            $0.value
        }.filter {
            for menuContextType in $0.enableMenuContexts {
                /// 判断是否是支持类型的实例或者是继承这个类型的实例
                if menuContext.isKind(of: menuContextType) {
                    return true
                }
            }
            return false
        }
        Self.rwSignal.signal()
        var result: [MenuPlugin] = []
        /// 还需要将域内的插件加入到结果中
        for domainPluginContext in domainPluginContexts {
            if let plugin = domainPluginContext.plugin.init(menuContext: menuContext, pluginContext: domainPluginContext) {
                result.append(plugin)
            }
        }
        return result
    }

    private override init() {
        super.init()
    }
}
