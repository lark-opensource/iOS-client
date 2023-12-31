//
//  TitleBarPlugin.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/16.
//

import Foundation
import LarkUIKit
import SKFoundation

class TitleBarPlugin: WAPlugin {
    
    override var pluginType: WAPluginType {
        .base
    }
    
    required init(host: WAPluginHost) {
        super.init(host: host)
    }
    
    
    override func registerBridgeSevices() {
        guard let bridge = self.host?.container.hostBridge, let container = self.host?.container,
            let context = bridge.context else {
            Self.logger.error("bridge/container/context is nil")
            return
        }
        Self.logger.info("register Service for titlebar")
        
        let titleBarService = TitleBarService(bridge: bridge, context: context, container: container)
        titleBarService.hostPlugin = self
        bridge.register(service: titleBarService)
        bridge.register(service: TitleService(bridge: bridge, context: context, container: container))
    }
    
    func showMoreMenu(sourceView: UIView) {
        guard let menuPlugin = self.host?.container.hostPluginManager?.resolve(MoreMenuPlugin.self) else {
            spaceAssertionFailure("MoreMenuPlugin not register")
            return
        }
        Self.logger.info("showMoreMenu")
        menuPlugin.show(sourceView: sourceView)
    }
}
