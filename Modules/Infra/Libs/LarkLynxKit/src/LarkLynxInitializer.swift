//
//  LarkLynxInitializer.swift
//  LarkLynxKit
//
//  Created by bytedance on 2022/11/3.
//

import Foundation
import Lynx
import LKCommonsLogging

public final class LarkLynxInitializer {
    static let logger = Logger.oplog(LarkLynxInitializer.self, category: "CommonLynxContainer")
    public static let shared = LarkLynxInitializer()
    
    private var customComponentDic: [String: [String: (AnyClass, LynxShadowNode.Type?)]] = [:]
    static private let customComponentCacheLock = DispatchSemaphore(value: 1)
    
    private var globalDataDic: [String: [String: Any]] = [:]
    static private let globalDataCacheLock = DispatchSemaphore(value: 1)
    
    private var lynxGroupDic: [String: LynxGroup] = [:]
    static private let lynxGroupCacheLock = DispatchSemaphore(value: 1)
    
    private var jsModuleDic: [String: JSModuleEntity] = [:]
    static private let jsModuleCacheLock = DispatchSemaphore(value: 1)
    
    private var bridgeMethodDispatcherDic: [String: LarkLynxBridgeMethodProtocol] = [:]
    static private let bridgeMethodDispatcherCacheLock = DispatchSemaphore(value: 1)
    
    private var lynxBridgeMethodDic: [String: [String: LarkLynxMethod.Type]] = [:]
    static private let lynxBridgeMethodCacheLock = DispatchSemaphore(value: 1)

    private var resourceLoadersDic: [String: [LarkLynxResourceLoader]] = [:]
    static private let resourceLoadersCacheLock = DispatchSemaphore(value: 1)
    
    public init() {}
    
    /**
     业务方注册业务要使用的端上自定义的组件，按tag进行业务隔离

     - Parameters:
       - tag: 业务标识，由业务方定义
       - customComponentDic: 业务方要使用的端上自定义组件的数组
     */
    public func registerCustomComponents(tag: String, customComponentDic: [String: (AnyClass, LynxShadowNode.Type?)]) {
        Self.customComponentCacheLock.wait()
        defer {
            Self.customComponentCacheLock.signal()
        }
        Self.logger.info("LarkLynxInitializer: registerCustomComponents with tag:\(tag)")
        self.customComponentDic[tag] = customComponentDic
    }
    
    public func getCustomComponent(tag: String) -> [String: (AnyClass, LynxShadowNode.Type?)]? {
        Self.customComponentCacheLock.wait()
        defer {
            Self.customComponentCacheLock.signal()
        }
        Self.logger.info("LarkLynxInitializer: getExtensionUI with tag:\(tag)")
        return self.customComponentDic[tag]
    }
    
    
    /**
     业务方注册业务要使用的BridgeMethods，BridgeMethods使用BridgeMethod分发器分发，按tag进行业务隔离
     
     - Parameters:
       - tag: 业务标识，由业务方定义
       - bridgePluginDic: 业务方要使用的端上自定义组件的数组
     */
    public func registerLynxBridgeMethods(tag: String, bridgeMethodDic: [LarkLynxMethod.Type]) {
        Self.lynxBridgeMethodCacheLock.wait()
        defer {
            Self.lynxBridgeMethodCacheLock.signal()
        }
        Self.logger.info("LarkLynxInitializer: registerLynxBridgeMethod with tag:\(tag)")
        var bizBridgeMethodDic: [String: LarkLynxMethod.Type] = [:]
        for plugin in bridgeMethodDic {
            bizBridgeMethodDic[plugin.methodName()] = plugin
        }
        self.lynxBridgeMethodDic[tag] = bizBridgeMethodDic
    }
    
    public func getLynxBridgeMethods(tag: String) -> [String: LarkLynxMethod.Type]? {
        Self.lynxBridgeMethodCacheLock.wait()
        defer {
            Self.lynxBridgeMethodCacheLock.signal()
        }
        Self.logger.info("LarkLynxInitializer: getLynxBridgeMethods with tag:\(tag)")
        return self.lynxBridgeMethodDic[tag]
    }
    
    
    /**
     业务方注册Native向Lynx通过JSModule发送数据的JSModule名和function名
     
     - Parameters:
       - tag: 业务标识，由业务方定义
       - entity: JSModule名和function名的数据体
     */
    
    public func registerJSModule(tag: String, entity: JSModuleEntity) {
        Self.jsModuleCacheLock.wait()
        defer {
            Self.jsModuleCacheLock.signal()
        }
        Self.logger.info("LarkLynxInitializer: registerJSModule with tag:\(tag)")
        self.jsModuleDic[tag] = entity
    }
    
    public func getJSModule(tag: String) -> JSModuleEntity? {
        Self.jsModuleCacheLock.wait()
        defer {
            Self.jsModuleCacheLock.signal()
        }
        Self.logger.info("LarkLynxInitializer: getJSModule with tag:\(tag)")
        return self.jsModuleDic[tag]
    }
    
    /**
     业务方注册业务可复用的全局数据，按tag进行业务隔离
     
     - Parameters:
       - tag: 业务标识，由业务方定义
       - globalData: 业务方要使用的端上自定义组件的数组
     */
    public func registerGlobalData(tag: String, globalData: [String: Any]) {
        Self.globalDataCacheLock.wait()
        defer {
            Self.globalDataCacheLock.signal()
        }
        Self.logger.info("LarkLynxInitializer: registerGlobalData with tag:\(tag)")
        self.globalDataDic[tag] = globalData
    }
    
    public func getGlobalData(tag: String) -> [String: Any]? {
        Self.globalDataCacheLock.wait()
        defer {
            Self.globalDataCacheLock.signal()
        }
        Self.logger.info("LarkLynxInitializer: getGlobalData with tag:\(tag)")
        return self.globalDataDic[tag]
    }
    
    
    /**
     业务方注册可复用的LynxGroup，用于多个LynxView的共享JS Context，按tag进行业务隔离

     - Parameters:
       - groupName: 业务标识，由业务方定义
       - lynxGroup: LynxGroup
     */
    public func registerLynxGroup(groupName: String, lynxGroup: LynxGroup) {
        Self.lynxGroupCacheLock.wait()
        defer {
            Self.lynxGroupCacheLock.signal()
        }
        Self.logger.info("LarkLynxInitializer: registerLynxGroup with groupName:\(groupName)")
        self.lynxGroupDic[groupName] = lynxGroup
    }
    
    
    /**
     业务方注册可复用的LynxGroup，只需要传入groupName，使用lynx内置的core.js

     - Parameters:
       - groupName: 业务标识，由业务方定义
     */
    public func registerLynxGroup(groupName: String) {
        Self.lynxGroupCacheLock.wait()
        defer {
            Self.lynxGroupCacheLock.signal()
        }
        Self.logger.info("LarkLynxInitializer: registerLynxGroup without lynxGroup, groupName:\(groupName)")
        self.lynxGroupDic[groupName] = LynxGroup(name: groupName)
    }
    
    public func getLynxGroup(groupName: String) -> LynxGroup? {
        Self.lynxGroupCacheLock.wait()
        defer {
            Self.lynxGroupCacheLock.signal()
        }
        Self.logger.info("LarkLynxInitializer: getLynxGroup with groupName:\(groupName)")
        return self.lynxGroupDic[groupName]
    }
    
    
    /**
     业务方注册实现Lynx JSBridge协议的实例，按tag进行业务隔离

     - Parameters:
       - tag: 业务标识，由业务方定义
       - impl: 实现Lynx JSBridge协议的实例
     */
    public func registerBridgeMethodDispatcher(tag: String, impl: LarkLynxBridgeMethodProtocol) {
        Self.bridgeMethodDispatcherCacheLock.wait()
        defer {
            Self.bridgeMethodDispatcherCacheLock.signal()
        }
        Self.logger.info("LarkLynxInitializer: registerBridgeMethodImpl with tag:\(tag)")
        self.bridgeMethodDispatcherDic[tag] = impl
    }

    public func getBridgeMethodDispatcher(tag: String) -> LarkLynxBridgeMethodProtocol? {
        Self.bridgeMethodDispatcherCacheLock.wait()
        defer {
            Self.bridgeMethodDispatcherCacheLock.signal()
        }
        Self.logger.info("LarkLynxInitializer: getBridgeMethodImpl with tag:\(tag)")
        return self.bridgeMethodDispatcherDic[tag]
    }

    public func registerResourceLoaders(tag: String, resourceLoaders: [LarkLynxResourceLoader]) {
        Self.resourceLoadersCacheLock.wait()
        defer {
            Self.resourceLoadersCacheLock.signal()
        }
        Self.logger.info("LarkLynxInitializer: register lynxResourceManager with tag: \(tag)")
        resourceLoadersDic[tag] = resourceLoaders
    }

    public func getResourceLoaders(tag: String) -> [LarkLynxResourceLoader]? {
        Self.resourceLoadersCacheLock.wait()
        defer {
            Self.resourceLoadersCacheLock.signal()
        }
        Self.logger.info("LarkLynxInitializer: get lynxResourceManager with tag: \(tag)")
        return resourceLoadersDic[tag]
    }
}
