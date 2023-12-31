//
//  WAPluginManager.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/13.
//

import Foundation
import LKCommonsLogging
import ThreadSafeDataStructure

public final class WAPluginManager {
    static let logger = Logger.log(WAPluginManager.self, category: WALogger.TAG)
    private(set) weak var container: WAContainer?
    private var plugins: SafeArray<WAPlugin> = [] + .semaphore
    
    deinit {
        plugins.forEach {
            $0.onDettachHost()
        }
        plugins.removeAll()
    }
    
    func setup(container: WAContainer) {
        self.container = container
        container.lifeCycleObserver.addListener(self)
    }
    
    public func resolve<H: WAPlugin>(_ pluginType: H.Type) -> H? {
        let plugin = plugins.first { type(of: $0) == pluginType }
        return plugin as? H
    }
    
    public func register(plugin: WAPlugin) {
        plugins.append(plugin)
        plugin.onAttachHost()
        
        let isAttachOnPage = self.container?.isAttachOnPage ?? false
        if plugin.pluginType == .base || isAttachOnPage {
            plugin.registerBridgeSevices()
        }
        
        Self.logger.info("register plugin:\(String(describing: type(of: plugin)))", tag: LogTag.plugin.rawValue)
    }
    
    private func unRegisterUIPlugins() {
        var basePlugins = [WAPlugin]()
        plugins.forEach {
            if $0.pluginType == .UI {
                $0.onDettachHost()
            } else {
                basePlugins.append($0)
            }
        }
        Self.logger.info("unRegisterUIPlugins，before:\(plugins.count),after:\(basePlugins.count)", tag: LogTag.plugin.rawValue)
        plugins.replaceInnerData(by: basePlugins)
    }
    
}

extension WAPluginManager: WAContainerLifeCycleListener {
    public func containerAttachToPage() {
        plugins.forEach { plugin in
            if plugin.pluginType == .UI {
                plugin.registerBridgeSevices()
            }
        }
    }
    
    public func containerDettachFromPage() {
        unRegisterUIPlugins()
    }
}
