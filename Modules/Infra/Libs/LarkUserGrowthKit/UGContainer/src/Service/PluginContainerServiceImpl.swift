//
//  PluginContainerServiceImpl.swift
//  UGContainer
//
//  Created by mochangxing on 2021/1/24.
//

import Foundation
import ThreadSafeDataStructure
import LKCommonsLogging
import EENavigator

/// 插件容器外部依赖
public protocol PluginContainerDependency: AnyObject {
    /// 事件上报接口
    func reportEvent(event: ReachPointEvent)
}

/// 插件工厂
typealias PluginFactory = () -> ReachPointPlugin

public final class PluginContainerServiceImpl: PluginContainerService {
    static let log = Logger.log(PluginContainerServiceImpl.self, category: "UGReach.Container")
    let pluginManager = PluginManager()
    var dependency: PluginContainerDependency

    public var reachPointsInfo: [String: [String]] {
        var reachPointsInfo: [String: [String]] = [:]
        self.pluginManager.type2Plugin.forEach { (key, value) in
            guard let plugin = value.instance,
                  !plugin.curReachPointIds.isEmpty else {
                return
            }
            reachPointsInfo[key] = plugin.curReachPointIds
        }
        return reachPointsInfo
    }

    private let navigator: Navigatable
    public init(dependency: PluginContainerDependency, navigator: Navigatable) {
        self.dependency = dependency
        self.navigator = navigator
    }

    public func obtainReachPoint<T: ReachPoint>(reachPointId: String) -> T? {
        if !pluginManager.type2Plugin.keys.contains(T.reachPointType) {
            registerReachPointType(T.self, lazyInit: false)
        }
        guard let plugin = queryPlugin(reachPointType: T.reachPointType) else {
            Self.log.error("plugin not exist for \(T.reachPointType)")
            return nil
        }

        return plugin.obtainReachPoint(reachPointId: reachPointId)
    }

    public func recycleReachPoint(reachPointId: String, reachPointType: String) {
        guard let plugin = queryPlugin(reachPointType: reachPointType) else {
            Self.log.error("plugin not exist for \(reachPointType)")
            return
        }
        plugin.recycleReachPoint(reachPointId: reachPointId)
    }

    func registerPlugin(reachPointType: String, factory: @escaping PluginFactory, lazyInit: Bool) {
        pluginManager.addPlugin(reachPointType: reachPointType,
                                factory: factory,
                                instance: lazyInit ? nil : factory())
    }

    func unregisterePlugin(reachPointType: String) {
        pluginManager.removePlugin(reachPointType: reachPointType)
    }

    public func showReachPoint(reachPointId: String, reachPointType: String, data: Data) {
        guard let plugin = queryPlugin(reachPointType: reachPointType) else {
            Self.log.error("plugin not exist for \(reachPointType)")
            return
        }
        plugin.onShow(reachPointId: reachPointId, data: data)
    }

    public func hideReachPoint(reachPointId: String, reachPointType: String) {
        guard let plugin = queryPlugin(reachPointType: reachPointType) else {
            Self.log.error("plugin not exist for \(reachPointType)")
            return
        }
        plugin.onHide(reachPointId: reachPointId)
    }

    public func reportEvent(event: ReachPointEvent) {
        dependency.reportEvent(event: event)
    }

    private func queryPlugin(reachPointType: String) -> ReachPointPlugin? {
        let plugin = pluginManager.getPlugin(reachPointType: reachPointType)
        if var provider = plugin as? ContainerServiceProvider,
           provider.containerSevice == nil {
            provider.containerSevice = self
        }
        return plugin
    }

    func registerReachPointType<T: ReachPoint>(_ type: T.Type, lazyInit: Bool = true) {
        let navigator = self.navigator
        registerPlugin(reachPointType: type.reachPointType, factory: { () -> ReachPointPlugin in
            return BasePlugin<T>(navigator: navigator)
        }, lazyInit: lazyInit)
    }
}
