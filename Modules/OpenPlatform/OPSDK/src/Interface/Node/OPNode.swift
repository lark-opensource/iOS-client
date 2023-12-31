//
//  OPNode.swift
//  OPSDK
//
//  Created by yinyuan on 2020/10/27.
//

import Foundation
import OPFoundation

/// 支撑事件和插件体系的Node协议。实现该协议的对象能够快速接入本框架从而获得事件派发、拦截、处理，以及插件注入的能力。
@objc public protocol OPNodeProtocol: OPEventTargetProtocol, OPEventNodeProtocol, OPPluginManagerProtocol {
    
    /// 父节点
    var parent: OPNodeProtocol? { get set }
    
    /// 添加一个子节点，如果重复添加，会先移除已添加的节点并重新添加
    /// - Parameter node: 子节点
    func addChild(node: OPNodeProtocol)
    
    /// 移除一个子节点
    /// - Parameter node: 子节点
    func removeChild(node: OPNodeProtocol) -> Bool
    
    /// 通过条件查找首个满足条件的child
    /// - Parameter predicate: 查找条件
    /// - Returns: 返回节点，如果未找到返回 nil
    func getChild(where predicate: (OPNodeProtocol) -> Bool) -> OPNodeProtocol?
    
}

/// OPNodeProtocol 的一个默认实现。
@objcMembers open class OPNode: NSObject, OPNodeProtocol {

    /// 修复切换租户时必现BDPTask内存泄漏问题。Doc: https://bytedance.feishu.cn/docs/doccnpRNk9ibhcNlrv7ky9sFiub#
    private weak var _parent: OPNodeProtocol?
    
    private let eventDispatcher: OPEventDispatcher = OPEventDispatcher()
    
    private let pluginManager: OPPluginManager = OPPluginManager()
    
    public override init() {
        super.init()
    }
    
    public var parent: OPNodeProtocol? {
        get {
            return _parent
        }
        
        set {
            if let oldParent = _parent {
                if oldParent.isEqual(newValue) {
                    return
                } else {
                    _ = oldParent.removeChild(node: self)
                }
            }
            _parent = newValue
            _parent?.addChild(node: self)
        }
    }
    
    private var children: [OPNodeProtocol] = []
    
    public func addChild(node: OPNodeProtocol) {
        if children.contains { (_node) -> Bool in
            _node.isEqual(node)
        } {
            return
        }
        children.append(node)
        node.parent = self
    }
    
    public func removeChild(node: OPNodeProtocol) -> Bool {
        var index = 0
        for _node in children {
            if _node.isEqual(node) {
                children.remove(at: index)
                node.parent = nil
                return true
            }
            index+=1
        }
        return false
    }
    
    /// 通过条件查找首个满足条件的child
    public func getChild(where predicate: (OPNodeProtocol) -> Bool) -> OPNodeProtocol? {
        return children.first(where: predicate)
    }

}

extension OPNode {
    
    public func interceptEvent(event: OPEvent, callback: OPEventCallback) -> Bool {
        if pluginManager.interceptEvent(event: event, callback: callback) {
            return true
        }
        return false
    }
    
    public func handleEvent(event: OPEvent, callback: OPEventCallback) -> Bool {
        if pluginManager.handleEvent(event: event, callback: callback) {
            return true
        }
        return false
    }
    
}

extension OPNode {
    
    public func sendEvent(eventName: String, params: [String: AnyHashable], callbackBlock: @escaping OPEventCallbackBlock, context: OPEventContext) -> Bool {
        let event = OPEvent(eventName: eventName, params: params, srcNode: self, context: context)
        // 发送事件
        return eventDispatcher.sendEvent(event: event, callback: OPEventCallback(callbackBlock: callbackBlock))
    }
    
    public func prepareEventContext(context: OPEventContext) {
        // 准备上下文
    }

}

extension OPNode {

    public func registerPlugins(plugins: [OPPluginProtocol]) {
        plugins.forEach { plugin in
            registerPlugin(plugin: plugin)
        }
    }

    public func registerPlugin(plugin: OPPluginProtocol) {
        pluginManager.registerPlugin(plugin: plugin)
    }
    
    public func unregisterPlugin(plugin: OPPluginProtocol) {
        pluginManager.unregisterPlugin(plugin: plugin)
    }
    
    public func unregisterAllPlugins() {
        pluginManager.unregisterAllPlugins()
    }
}
