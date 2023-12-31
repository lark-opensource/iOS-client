//
//  WABridgeInvocation.swift
//  WebAppBridge
//
//  Created by lijuyou on 2023/11/12.
//

import Foundation
import LarkWebViewContainer

public struct WABridgeInvocation {
    
    public let name: String
    
    public let params: [String: Any]
    
//    public let data: T?
    
    public let callback: APICallbackProtocol?
}
