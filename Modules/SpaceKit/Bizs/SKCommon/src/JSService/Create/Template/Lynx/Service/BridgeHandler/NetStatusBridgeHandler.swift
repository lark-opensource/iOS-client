//
//  NetStatusBridgeHandler.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2022/5/13.
//  


import Foundation
import SKFoundation
import BDXServiceCenter
import BDXBridgeKit

protocol SKLynxGlobalEventHandler: AnyObject {
    func requestSend(event: GlobalEventEmiter.Event)
}

extension LynxBaseViewController: SKLynxGlobalEventHandler {
    func requestSend(event: GlobalEventEmiter.Event) {
        globalEventEmiter.send(event: event)
    }
}

class NetStatusBridgeHandler: BridgeHandler {
    let methodName = "ccm.getNetStatus"

    let handler: BDXLynxBridgeHandler
    
    init(hostController: SKLynxGlobalEventHandler) {
        handler = { (_, _, params, callback) in
            let params = Self.createParamsForCurrentNetStatus()
            callback(BDXBridgeStatusCode.succeeded.rawValue, params)
        }
        DocsNetStateMonitor.shared.addObserver(hostController) { [weak hostController] accessType, isReachable in
            guard let hostVC = hostController else {
                return
            }
            let event = GlobalEventEmiter.Event(
                name: "ccm.netStateChangedEvent",
                params: [
                    "type": accessType.rawValue,
                    "isConnected": isReachable
                ]
            )
            hostVC.requestSend(event: event)
        }
    }

    static func createParamsForCurrentNetStatus() -> [String: Any] {
        return [
            "type": DocsNetStateMonitor.shared.accessType.rawValue,
            "isConnected": DocsNetStateMonitor.shared.isReachable
        ]
    }

}
