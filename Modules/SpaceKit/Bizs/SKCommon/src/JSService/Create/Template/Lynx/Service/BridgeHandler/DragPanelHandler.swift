//
//  DragPanelHandler.swift
//  SKCommon
//
//  Created by zengsenyuan on 2022/6/7.
//  


import SKFoundation
import BDXLynxKit
import BDXServiceCenter
import BDXBridgeKit


class DragPanelHandler: BridgeHandler {
    
    enum DragPanelType: String {
        case show
        case close
    }
    
    let methodName = "ccm.showDragPanel"
    var handler: BDXLynxBridgeHandler
    
    init(callbackHandler: ((_ type: DragPanelType, _ params: String) -> Void)? = nil) {
        handler = {(_, _, params, callback) in
            guard let typeValue = params?["type"] as? String,
                  let type = DragPanelType(rawValue: typeValue)  else {
                DocsLogger.error("registerCCMDragPanelHandler fail params is wrong")
                callback(BDXBridgeStatusCode.failed.rawValue, nil)
                return
            }
            DocsLogger.info("registerCCMDragPanelHandler success type: \(typeValue)")
            DocsLogger.info("registerCCMDragPanelHandler params: \(params)")
            callbackHandler?(type, (params?["params"] as? String) ?? "")
            callback(BDXBridgeStatusCode.succeeded.rawValue, nil)
        }
    }
}
