//
//  WABridgeServiceContext.swift
//  WebAppBridge
//
//  Created by lijuyou on 2023/10/30.
//

import Foundation

public protocol WABridgeServiceContext: AnyObject {
    
    var bizName: String { get }
    
    var host: WABridgeServiceHost { get }
}
