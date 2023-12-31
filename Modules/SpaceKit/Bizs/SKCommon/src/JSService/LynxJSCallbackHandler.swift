//
//  LynxJSCallbackHandler.swift
//  SKBitable
//
//  Created by zoujie on 2022/3/15.
//  


import SKFoundation
import BDXServiceCenter
import BDXBridgeKit
import UIKit

//lynx通过native callback回前端
public final class LynxJSCallbackHandler: BridgeHandler {
    public let methodName = "ccm.executeJSBridgeCallback"

    public let handler: BDXLynxBridgeHandler

    public init(model: BrowserModelConfig?) {
        handler = { [weak model] (_, _, params, lynxCallback) in
            guard let callback = params?["callbackId"] as? String else { return }
            DocsLogger.info("LynxJSCallbackHandler callback:\(callback)")

            let params = params?["params"] as? [String: Any]

            model?.jsEngine.callFunction(DocsJSCallBack(callback), params: params, completion: { result, error in
                guard error == nil else {
                    lynxCallback(BDXBridgeStatusCode.failed.rawValue, ["message": "\(callback) error:\(error)"])
                    return
                }

                lynxCallback(BDXBridgeStatusCode.succeeded.rawValue, ["response": (result as? [String: Any]) ?? ""])
            })
        }
    }
}
