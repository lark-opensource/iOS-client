//
//  OPPluginBase.swift
//  OPSDK
//
//  Created by Nicholas Tau on 2021/1/14.
//

import Foundation
import LKCommonsLogging

@objcMembers
open class OPPluginBase : NSObject, OPPluginProtocol {
    
    open func pluginDidLoad() {

    }
    
    open func handleEvent(event: OPEvent, callback: OPEventCallback) -> Bool {
        return false
    }
    
    public func interceptEvent(event: OPEvent, callback: OPEventCallback) -> Bool {
        return false
    }
    
    public var filters: [String] = []
}
