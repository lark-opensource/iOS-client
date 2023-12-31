//
//  LynxJSBridgeHandler.swift
//  SKBitable
//
//  Created by zoujie on 2022/3/15.
//  


import SKFoundation
import BDXServiceCenter
import BDXBridgeKit
import UIKit

//lynx通过native调用前端bridge
public final class LynxJSBridgeHandler: BridgeHandler {
    public let methodName = "ccm.callJSMethod"

    public let handler: BDXLynxBridgeHandler

    public init(model: BrowserModelConfig?) {
        handler = { [weak model] (_, _, params, lynxCallback) in
            guard let eventName = params?["method"] as? String else { return }

            DocsLogger.info("LynxJSCallbackHandler eventName:\(eventName)")
            let params = params?["params"] as? [String: Any]

            model?.jsEngine.callFunction(DocsJSCallBack(eventName), params: params, completion: { result, error in
                guard error == nil else {
                    lynxCallback(BDXBridgeStatusCode.failed.rawValue, ["message": "\(eventName) error:\(error)"])
                    return
                }
                lynxCallback(BDXBridgeStatusCode.succeeded.rawValue, ["data": (result as? [String: Any]) ?? ""])
            })
        }
    }
}
