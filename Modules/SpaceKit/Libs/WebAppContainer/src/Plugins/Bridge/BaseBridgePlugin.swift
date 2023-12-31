//
//  BaseBridgePlugin.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/16.
//

import Foundation


/// 管理基础Bridge的插件
class BaseBridgePlugin: WAPlugin {
    
    var bridge: WABridge? {
        self.host?.container.hostBridge
    }
    
    override var pluginType: WAPluginType {
        .base
    }
    
    required init(host: WAPluginHost) {
        super.init(host: host)
    }
    
    override func registerBridgeSevices() {
        Self.logger.info("register BaseBridgePlugin")
        guard let bridge,
            let context = bridge.context,
              let container = self.host?.container else {
            Self.logger.error("bridge/context/container is nil")
            return
        }
        bridge.register(service: LoggerService(bridge: bridge, context: context))
        bridge.register(service: TemplateReadyService(bridge: bridge, context: context))
        bridge.register(service: LoadFinishService(bridge: bridge, context: context, container: container))
        bridge.register(service: UserInfoService(bridge: bridge, context: context, container: container))
    }
}
