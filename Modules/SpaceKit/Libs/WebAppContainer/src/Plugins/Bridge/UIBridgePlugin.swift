//
//  UIBridgePlugin.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/19.
//

import Foundation

/// /// 管理依赖UI相关的Bridge的插件
class UIBridgePlugin: WAPlugin {
    
    var bridge: WABridge? {
        self.host?.container.hostBridge
    }
    
    override var pluginType: WAPluginType {
        .UI
    }
    
    required init(host: WAPluginHost) {
        super.init(host: host)
        self.host?.container.lifeCycleObserver.addListener(self)
    }
    
    override func registerBridgeSevices() {
        Self.logger.info("register UIBridgePlugin")
        guard let bridge, let container = self.host?.container,
              let context = bridge.context else {
            Self.logger.error("bridge/container/context is nil")
            return
        }
        bridge.register(service: ClosePageService(bridge: bridge, context: context, container: container))
        bridge.register(service: RefreshPageService(bridge: bridge, context: context, container: container))
        bridge.register(service: ToastService(bridge: bridge, context: context))
    }
}

extension UIBridgePlugin: WAContainerLifeCycleListener {
    
    public func containerDettachFromPage() {
        //页面关闭时注销UI相关Service
        self.bridge?.unRegisterService(for: .UI)
    }
}
