//
//  OPJSBridgeModuleMessageHandlers.swift
//  OPJSEngine
//
//  Created by yi on 2022/2/14.
//

import Foundation
import LKCommonsLogging

@objc protocol OPJSBridgeMessageHandlersProtocol: JSExport {
    var messageHandlers: [String: Any] { get }

}

@objc class OPJSBridgeModuleMessageHandlers: NSObject, OPJSBridgeMessageHandlersProtocol {
    
    static let logger = Logger.log(OPJSBridgeModuleMessageHandlers.self, category: "OPJSEngine")
    
    private weak var jsRuntime: GeneralJSRuntime?
    
    private var eventHandler: OPJSEventHandlers?
    
    public init(jsRuntime: GeneralJSRuntime?) {
        self.jsRuntime = jsRuntime
        super.init()
        
        if let jsRuntime = jsRuntime {
            self.eventHandler = OPJSEventHandlers(jsRuntime: jsRuntime)
        }
    }
    
    @objc public func invokeNative(jsValue: JSValue) -> Any? {
        var dic: [AnyHashable: Any]?

        // 开关打开，走新逻辑
        dic = jsValue.bdp_convert2Object()

        if let dic = dic as? [String: Any] {
            return eventHandler?.invokeNative(dic: dic)
        } else {
            Self.logger.error("bridge invokeNative fail, parameter is nil")
            return nil
        }
    }
    
    @objc public func publish(jsValue: JSValue) -> Any? {

        if let dic = jsValue.toObject() as? [String: Any] {
            return eventHandler?.publish(dic: dic)
        }
        return nil

    }
    var messageHandlers: [String: Any] {
        get {
            let bridgePostMessage: @convention(block) (JSValue) -> Any? = { [weak self] jsValue in
                guard let `self` = self else {
                    Self.logger.error("worker bridgePostMessage fail, self is nil")
                    return nil
                }
                return self.invokeNative(jsValue:jsValue)
            }

            let publish2: @convention(block) (JSValue) -> Any? = { [weak self] jsValue in

                guard let `self` = self else {
                    Self.logger.error("worker publish2 fail, self is nil")
                    return nil
                }
                return self.publish(jsValue:jsValue)
            }

            return ["invokeNative" : ["postMessage": bridgePostMessage], "publish2" : ["postMessage": publish2]]

        }
    }
}
