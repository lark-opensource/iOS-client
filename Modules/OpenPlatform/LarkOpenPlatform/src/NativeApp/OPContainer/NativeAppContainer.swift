//
//  NativeAppContainer.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2022/12/28.
//

import Foundation
import OPSDK
import TTMicroApp

@objcMembers public class NativeAppContainer: NSObject, OPContainerProtocol {
    public func removeTemporaryTab() {
    }
    
    public var bridge: OPSDK.OPBridgeProtocol
    
    public var containerContext: OPSDK.OPContainerContext
    
    public var updater: OPSDK.OPContainerUpdaterProtocol?
    
    public var runtimeVersion: String
    
    public var sandbox: BDPSandboxProtocol?
    
    public var isSupportDarkMode: Bool
    
    public var parent: OPSDK.OPNodeProtocol?
    
    init(applicationContext: OPApplicationContext, uniqueID: OPAppUniqueID, containerConfig: OPContainerConfigProtocol) {
        let containerContext = OPContainerContext(applicationContext: applicationContext, uniqueID: uniqueID, containerConfig: containerConfig)
        self.containerContext = containerContext
        let bridge = OPBaseBridge()
        self.bridge = bridge
        self.runtimeVersion = ""
        self.isSupportDarkMode = false
        self.sandbox = (BDPModuleManager(of: .thirdNativeApp)
            .resolveModule(with: BDPStorageModuleProtocol.self) as? BDPStorageModuleProtocol)?
            .createSandbox(with: containerContext.uniqueID, pkgName: uniqueID.appID)
    }
    
    public func addLifeCycleDelegate(delegate: OPSDK.OPContainerLifeCycleDelegate) {}
    
    public func mount(data: OPSDK.OPContainerMountDataProtocol, renderSlot: OPSDK.OPRenderSlotProtocol) {}
    
    public func unmount(monitorCode: OPMonitorCode) {}
    
    public func reload(monitorCode: OPMonitorCode) {}
    
    public func destroy(monitorCode: OPMonitorCode) {}
    
    public func notifySlotShow() {}
    
    public func notifySlotHide() {}
    
    public func notifyPause() {}
    
    public func notifyResume() {}
    
    public func notifyThemeChange(theme: String) {}
    
    public func addChild(node: OPSDK.OPNodeProtocol) {}
    
    public func prepareEventContext(context: OPSDK.OPEventContext) {}
    
    public func registerPlugin(plugin: OPSDK.OPPluginProtocol) {}
    
    public func unregisterPlugin(plugin: OPSDK.OPPluginProtocol) {}
    
    public func registerPlugins(plugins: [OPSDK.OPPluginProtocol]) {}
    
    public func unregisterAllPlugins() {}
    
    public func removeChild(node: OPSDK.OPNodeProtocol) -> Bool {
        return false
    }
    
    public func getChild(where predicate: (OPSDK.OPNodeProtocol) -> Bool) -> OPSDK.OPNodeProtocol? {
        return nil
    }
    
    public func interceptEvent(event: OPSDK.OPEvent, callback: OPSDK.OPEventCallback) -> Bool {
        return false
    }
    
    public func handleEvent(event: OPSDK.OPEvent, callback: OPSDK.OPEventCallback) -> Bool {
        return false
    }
    
    public func sendEvent(eventName: String, params: [String : AnyHashable], callbackBlock: @escaping OPSDK.OPEventCallbackBlock, context: OPSDK.OPEventContext) -> Bool {
        return false
    }
}
