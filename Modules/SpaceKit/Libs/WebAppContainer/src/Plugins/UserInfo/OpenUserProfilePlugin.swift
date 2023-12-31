//
//  OpenUserProfilePlugin.swift
//  WebAppContainer
//
//  Created by majie.7 on 2023/11/22.
//

import Foundation
import SKFoundation

class OpenUserProfilePlugin: WAPlugin {
    override var pluginType: WAPluginType {
        .UI
    }
    
    override func registerBridgeSevices() {
        guard let bridge = self.host?.container.hostBridge, let container = self.host?.container,
            let context = bridge.context else {
            Self.logger.error("openUserProfile: bridge/container/context is nil")
            return
        }
        Self.logger.info("register Service for open user profile")
        
        let service = OpenUserProfileBridgeService(bridge: bridge, context: context, container: container)
        service.profilePlugin = self
        bridge.register(service: service)
    }
    
    func openProfile(userId: String) {
        guard let fromVC = self.host?.container.hostVC else { return }
        
        let service = OpenUserProfileService(userId: userId, fromVC: fromVC, fileName: nil, params: [:])
        HostAppBridge.shared.call(service)
    }
}

class OpenUserProfileBridgeService: WASimpleContainerBridgeService {
    
    override var name: WABridgeName {
        .openUserProfile
    }
    
    weak var profilePlugin: OpenUserProfilePlugin?
    
    override func handle(invocation: WABridgeInvocation) {
        guard let userId = invocation.params["uid"] as? String else {
            Self.logger.info("openUserProfile: can not get user id from invocation params")
            return
        }

        profilePlugin?.openProfile(userId: userId)
    }
}

