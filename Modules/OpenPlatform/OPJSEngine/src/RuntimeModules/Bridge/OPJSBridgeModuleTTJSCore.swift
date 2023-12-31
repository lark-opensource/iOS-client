//
//  OPJSBridgeModuleTTJSCore.swift
//  OPJSEngine
//
//  Created by yi on 2022/2/14.
//

import Foundation

// ttjscore对象
@objc protocol OPJSBridgeTTJSCoreProtocol: JSExport {
    func invoke(_ ev: String, _ param: String, _ callbackID: NSNumber) -> String?
    func publish(_ ev: String, _ param: String, _ callbackID: String)
    func call(_ ev: String, _ param: JSValue, _ callbackID: NSNumber) -> JSValue?
    func onDocumentReady()
    func setTimer(_ type: String, _ functionID: Int, _ delay: Int)
    func clearTimer(_ type: String, _ functionID: Int)
}

@objc class OPJSBridgeModuleTTJSCore: NSObject, OPJSBridgeTTJSCoreProtocol {
    private weak var jsRuntime: GeneralJSRuntime?
    
    private var eventHandler: OPJSEventHandlers?
    
    public init(jsRuntime: GeneralJSRuntime?) {
        self.jsRuntime = jsRuntime
        super.init()
        
        if let jsRuntime = jsRuntime {
            self.eventHandler = OPJSEventHandlers(jsRuntime: jsRuntime)
        }
    }

    func invoke(_ ev: String, _ param: String, _ callbackID: NSNumber) -> String? {
        return eventHandler?.invoke(ev, param, callbackID)
    }
    
    func publish(_ ev: String, _ param: String, _ callbackID: String)
    {
        eventHandler?.publish(ev, param, callbackID)
    }
    
    func call(_ ev: String, _ param: JSValue, _ callbackID: NSNumber) -> JSValue?
    {
        if let resultDic = eventHandler?.call(ev, param.bdp_object(), callbackID),
           let context = jsRuntime?.jsContext {
            return resultDic.bdp_jsvalue(in: context)
        }
        
        return nil
    }
        
    func onDocumentReady() {
        eventHandler?.onDocumentReady()
    }
        
    func setTimer(_ type: String, _ functionID: Int, _ delay: Int)
    {
        eventHandler?.setTimer(type, functionID, delay)
    }

    func clearTimer(_ type: String, _ functionID: Int) {
        eventHandler?.clearTimer(type, functionID)
    }

}
