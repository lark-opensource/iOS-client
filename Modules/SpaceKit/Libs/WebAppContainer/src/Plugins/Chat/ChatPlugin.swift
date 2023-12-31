//
//  ChatPlugin.swift
//  WebAppContainer
//
//  Created by majie.7 on 2023/11/23.
//

import Foundation
import SKFoundation
import EENavigator

class ChatPlugin: WAPlugin {
    override var pluginType: WAPluginType {
        .UI
    }
    
    override func registerBridgeSevices() {
        guard let bridge = self.host?.container.hostBridge,
              let container = self.host?.container,
              let context = bridge.context else {
            Self.logger.error("chat plugin: bridge/container/context is nil")
            return
        }
        Self.logger.info("chat plugin: register service for open chat")
        
        let service = ChatBridgeService(bridge: bridge, context: context, container: container)
        service.chatPlugin = self
        bridge.register(service: service)
    }
    
    func openChat(data: WAOpenChatBody, fromVC: UIViewController) {
        Navigator.shared.showDetailOrPush(body: data, from: fromVC)
    }
}


class ChatBridgeService: WASimpleContainerBridgeService {
    
    override var name: WABridgeName {
        .openChat
    }
    
    weak var chatPlugin: ChatPlugin?
    
    override func handle(invocation: WABridgeInvocation) {
        guard let data: WAOpenChatBody = self.transform(invocation.params) else {
            Self.logger.error("chat plugin: openChat params error")
            return
        }
        guard let fromVC = self.uiAgent?.bridgeVC else {
            Self.logger.error("chat plugin: can not get from vc to open chat")
            return
        }
        
        chatPlugin?.openChat(data: data, fromVC: fromVC)
    }
}
