//
//  OPBaseBridge.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/19.
//

import Foundation

public protocol OPBaseBridgeDelegate: AnyObject {
    
    func sendEventToBridge(
        eventName: String,
        params: [AnyHashable : Any]?,
        callback: OPBridgeCallback?) throws
    
}

@objcMembers public final class OPBaseBridge: NSObject, OPBridgeProtocol {
    
    public weak var delegate: OPBaseBridgeDelegate?
    
    public func sendEvent(
        eventName: String,
        params: [AnyHashable : Any]?,
        callback: OPBridgeCallback?) throws {
        try delegate?.sendEventToBridge(eventName: eventName, params: params, callback: callback)
    }
    
}

