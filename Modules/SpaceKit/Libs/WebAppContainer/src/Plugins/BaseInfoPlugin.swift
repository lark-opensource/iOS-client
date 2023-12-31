//
//  BaseInfoPlugin.swift
//  WebAppContainer
//
//  Created by majie.7 on 2023/11/29.
//

import Foundation
import LarkContainer


class BaseInfoPlugin: WAPlugin {
    override var pluginType: WAPluginType {
        .base
    }
    
    override func registerBridgeSevices() {
        guard let bridge = self.host?.container.hostBridge, let container = self.host?.container,
            let context = bridge.context else {
            Self.logger.error("BaseInfoPlugin: bridge/container/context is nil")
            return
        }
        Self.logger.info("register Service for get baseInfo")
        
        let service = BaseInfoBridgeService(bridge: bridge, context: context, container: container)
        service.baseInfoPlugin = self
        bridge.register(service: service)
    }
    
    func getBaseInfo() -> [String: Any]? {
        guard let container = host?.container,
              let baseInfo = try? container.userResolver.resolve(assert: WABaseInfoProtocol.self) else {
            return nil
        }
        var dict = baseInfo.toDic()
        dict["webviewCreateTime"] = container.timing.createWebView
        dict["startLoadUrlTime"] = container.timing.startLoadUrl
        return dict
        
    }
}

class BaseInfoBridgeService: WASimpleContainerBridgeService {
    
    override var name: WABridgeName {
        .getBaseInfo
    }
    
    weak var baseInfoPlugin: BaseInfoPlugin?
    
    override func handle(invocation: WABridgeInvocation) {
        let dic = baseInfoPlugin?.getBaseInfo()
        guard let dic else {
            invocation.callback?.callbackFailure(param: ["success": false, "msg": "native can't get baseInfo"])
            return
        }
        invocation.callback?.callbackSuccess(param: dic)
    }
}
