//
//  WAPlugin.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/13.
//

import Foundation
import LKCommonsLogging

public enum WAPluginType {
    case base
    case UI
    
    var serviceType: WABridgeServiceType {
        switch self {
        case .base:
            return .base
        case .UI:
            return .UI
        }
    }
}

open class WAPlugin: NSObject {
    static let logger = Logger.log(WAPlugin.self, category: WALogger.TAG)

    public weak var host: WAPluginHost?
    
    public var pluginType: WAPluginType {
        .base
    }
    
    public required init(host: WAPluginHost) {
        self.host = host
    }
    
    open func onAttachHost() {
        
    }
    
    open func onDettachHost() {
        
    }
    
    open func registerBridgeSevices() {
        
    }
    
    open func unRegisterBridgeSevices() {
        
    }
    
}
