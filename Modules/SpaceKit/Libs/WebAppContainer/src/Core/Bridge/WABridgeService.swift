//
//  WABridgeService.swift
//  WebAppBridge
//
//  Created by lijuyou on 2023/10/30.
//

import Foundation
import LarkWebViewContainer
import LKCommonsLogging

open class WABridgeService {
    
    public static let logger = LKCommonsLogging.Logger.log(WABridgeService.self, category: WALogger.TAG)
    
    public weak var context: WABridgeServiceContext?
    public weak var bridge: WABridge?
    
    open var serviceType: WABridgeServiceType { .base }
    
    public init(bridge: WABridge?, context: WABridgeServiceContext) {
        self.bridge = bridge
        self.context = context
    }
    
    open func getBridgeHandlers() -> [WABridgeHandler] {
        assertionFailure("must override in subclass!")
        return []
    }
    
    open func onAttach() {}
    
    open func onDettach() {}
}

extension WABridgeService {
    public var uiAgent: WABridgeUIDelegate? {
        self.context?.host.uiAgent
    }
}


///// 只处理单个Bridge的Service
open class WASimpleBridgeService: WABridgeService, WABridgeHandler {
    open var name: WABridgeName {
        assertionFailure()
        return .unknown
    }
    
    open override var serviceType: WABridgeServiceType {
        assertionFailure()
        return .base
    }
    
    
    open func handle(invocation: WABridgeInvocation) {
        assertionFailure()
    }
    
    open override func getBridgeHandlers() -> [WABridgeHandler] {
       return [self]
    }
    
}
