//
//  NativeAppConnectManager.swift
//  NativeAppPublicKit
//
//  Created by bytedance on 2022/6/8.
//

import Foundation

///提供端集成中DI相关桥接逻辑，提供飞书Native中关于端集成能力、三方API Manager、各NativeApp的DI能力
public class NativeAppConnectManager: NSObject {
    
    @objc
    public static let shared = NativeAppConnectManager()
    private var diContainer: [NativeAppProtocolType: Any] = [:]
    static private let diLock = DispatchSemaphore(value: 1)
    
    private var appIdArray: [String] = []
    static private let appIdLock = DispatchSemaphore(value: 1)
    
    private var nativeAppManager: NativeAppManagerProtocol?
    private var nativeAPIManager: NativeAppApiConfigProtocol?
    
    private override init() {
        let sel = NSSelectorFromString("setup")
        DispatchQueue.main.async {
            if let thirdPartEntry = NSClassFromString("ThirdPartApp.Entry") as? NSObjectProtocol, thirdPartEntry.responds(to: sel) {
                thirdPartEntry.perform(sel)
            }
        }
    }
    
    /**
     设置飞书Native端集成能力的DI对象

     - Parameters:
       - manager: 飞书Native端集成能力的DI对象
     */
    public func setupNativeAppManager(manager: NativeAppManagerProtocol) {
        self.nativeAppManager = manager
    }
    
    
    /**
     获取飞书Native端集成能力的DI对象
     */
    @objc
    public func getNativeAppManager() -> NativeAppManagerProtocol? {
        self.nativeAppManager
    }
    
    
    /**
     设置三方API Manager的DI对象

     - Parameters:
       - manager: 飞书Native端集成能力的DI对象
     */
    @objc
    public func setupAPIManager(manager: NativeAppApiConfigProtocol) {
        self.nativeAPIManager = manager
    }
    
    
    /**
     获取三方API Manager的DI对象
     */
    public func getAPIManager() -> NativeAppApiConfigProtocol? {
        self.nativeAPIManager
    }
    
    
    /**
     添加NativeApp的DI对象到DI容器

     - Parameters:
       - protocolType: 要添加的NativeApp对象实现的协议
       - impl: NativeApp对象
     */
    @objc
    public func setupDIItems(protocolType: NativeAppProtocolType, impl: NativeAppExtensionProtocol) {
        Self.diLock.wait()
        defer {
            Self.diLock.signal()
        }
        let appID = impl.getNativeAppId()
        if !appID.isEmpty, appID != "" {
            self.addAppID(appID: appID)
            if self.diContainer[protocolType] == nil {
                let dic = [appID: impl]
                self.diContainer[protocolType] = dic
            } else if var protocolTypeDic = self.diContainer[protocolType] as? [String: NativeAppExtensionProtocol] {
                protocolTypeDic[appID] = impl
                self.diContainer[protocolType] = protocolTypeDic
            } else {
                assertionFailure("DI info error,should not enter here")
            }
        } else {
            self.diContainer[protocolType] = impl
        }
    }
    
    
    /**
     从DI容器中获取NativeApp的DI对象

     - Parameters:
       - protocolType: 要获取的NativeApp对象实现的协议
     */
    @objc
    public func getDIItems(protocolType: NativeAppProtocolType) -> Any? {
        Self.diLock.wait()
        defer {
            Self.diLock.signal()
        }
        return self.diContainer[protocolType]
    }
    
    /**
     添加端能力对应的appID

     - Parameters:
       - appId: 端能力对应的appID
     */
    @objc
    private func addAppID(appID: String) {
        Self.appIdLock.wait()
        defer {
            Self.appIdLock.signal()
        }
        self.appIdArray.append(appID)
    }
    
    /**
     获取端能力appID列表
     */
    @objc
    public func appIDArray() -> [String] {
        Self.appIdLock.wait()
        defer {
            Self.appIdLock.signal()
        }
        return self.appIdArray
    }
    
}
