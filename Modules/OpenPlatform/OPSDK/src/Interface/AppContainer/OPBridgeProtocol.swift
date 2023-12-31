//
//  OPBridgeProtocol.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/19.
//

import Foundation

public typealias OPBridgeCallback = ((_ result: [AnyHashable: Any]?) -> Void)

@objc public protocol OPBridgeProtocol {
    
    func sendEvent(eventName: String, params: [AnyHashable: Any]?, callback: OPBridgeCallback?) throws
    
}
