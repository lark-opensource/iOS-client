//
//  ContainerBridgeHandler.swift
//  SKCommon
//
//  Created by zengsenyuan on 2022/7/6.
//  



import SKFoundation
import BDXLynxKit
import BDXServiceCenter
import BDXBridgeKit

class ContainerEventHandler: BridgeHandler {
    
    enum EventType: String {
        case onClick
        case onShow
        case closeContainer
    }
    
    let methodName = "ccm.sendContainerEvent"
    var handler: BDXLynxBridgeHandler
    
    init(callbackHandler: ((_ event: EventType, _ params: [String: Any]) -> Void)? = nil) {
        handler = {(_, _, params, callback) in
            guard let eventValue = params?["eventName"] as? String,
                  let event = EventType(rawValue: eventValue)  else {
                DocsLogger.error("registerContainerEventHandler fail params is wrong")
                callback(BDXBridgeStatusCode.failed.rawValue, nil)
                return
            }
            DocsLogger.info("registerContainerEventHandler success type: \(eventValue)")
            DocsLogger.info("registerContainerEventHandler params: \(params)")
            callbackHandler?(event, (params?["params"] as? [String: Any]) ?? [:])
            callback(BDXBridgeStatusCode.succeeded.rawValue, nil)
        }
    }
}
