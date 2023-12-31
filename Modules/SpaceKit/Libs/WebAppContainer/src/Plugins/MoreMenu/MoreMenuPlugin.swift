//
//  MoreMenuPlugin.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/19.
//

import Foundation
import LarkUIKit

class MoreMenuPlugin: WAPlugin, MenuPanelDelegate {
    
    override var pluginType: WAPluginType {
        .UI
    }
    
    private lazy var menuHandler: MenuPanelOperationHandler? = {
        self.makeMenuHandler()
    }()
    
    override func registerBridgeSevices() {
        guard let bridge = self.host?.container.hostBridge, let container = self.host?.container,
            let context = bridge.context else {
            Self.logger.error("bridge/container/context is nil")
            return
        }
        Self.logger.info("register Service for titlebar")
        
        let service = MoreMenuService(bridge: bridge, context: context, container: container)
        service.menuPlugin = self
        bridge.register(service: service)
    }
    
    func show(sourceView: UIView) {
        guard let container = self.host?.container else {
            return
        }
        let menuCtx = WAMenuContext(container: container)
        menuHandler?.makePlugins(with: menuCtx)
        menuHandler?.show(from: .init(sourceView: sourceView), parentPath: .init(path: "webapp"), animation: true) {
            //complete
        }
    }
    
    func makeMenuHandler() -> MenuPanelOperationHandler? {
        guard let hostVC = self.host?.container.hostVC else {
            return nil
        }
        let handler = MenuPanelHelper.getMenuPanelHandler(in: hostVC, for: .traditionalPanel)
        handler.delegate = self
        return handler
    }
    
    //MenuPanelDelegate
    func menuPanelItemDidClick(identifier: String?, model: MenuItemModelProtocol?) {
        Self.logger.info("click moremenu:\(identifier)")
    }
}

class MoreMenuService: WASimpleContainerBridgeService {
    
    override var name: WABridgeName {
        .showMenu
    }
    
    weak var menuPlugin: MoreMenuPlugin?
    
    override func handle(invocation: WABridgeInvocation) {
        
       // menuPlugin?.show(sourceView: )
    }
}
