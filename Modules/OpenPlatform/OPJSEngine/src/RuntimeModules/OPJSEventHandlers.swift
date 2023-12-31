//
//  OPJSBridgeHandlers.swift
//  OPJSEngine
//
//  Created by Jiayun Huang on 2022/2/17.
//

import Foundation
import LKCommonsLogging

class OPJSEventHandlers: NSObject {
    static let logger = Logger.log(OPJSEventHandlers.self, category: "OPJSEngine")
    
    private weak var jsRuntime : GeneralJSRuntime?
    
    public init(jsRuntime: GeneralJSRuntime?) {
        self.jsRuntime = jsRuntime
        
        super.init()
    }
    
    // Webkit events
    @objc public func invokeNative(dic: [String: Any]) -> Any? {
        guard let apiName = dic["apiName"] as? String else {
            Self.logger.error("invokeNative fail, no apiName")
            return nil
        }
        let param = dic["data"] as? [AnyHashable: Any]
        let callbackID = dic["callbackID"] as? String
        let extra = dic["extra"] as? [AnyHashable: Any]
        return jsRuntime?.invoke(event: apiName, param: param, callbackID: callbackID, extra: extra, isNewBridge: true)
    }
    
    @objc public func publish(dic: [String: Any]) {
        guard let apiName = dic["apiName"] as? String else {
            Self.logger.error("publish fail, no apiName")
            return
        }
        let param = dic["data"] as? [AnyHashable: Any]
        var appPageIDs: [NSNumber]?
        if let extra = dic["extra"] as? [AnyHashable: Any] {
            appPageIDs = extra["webviewIds"] as? [NSNumber]
        }
        jsRuntime?.delegate?.runtimePublish?(apiName, param: param, appPageIDs: appPageIDs, useNewPublish: true)
    }
    
    // TTJSCore events
    @objc func invoke(_ ev: String, _ param: String, _ callbackID: NSNumber) -> String? {
        guard let runtime = self.jsRuntime else {
            OPJSEventHandlers.logger.error("ttjscore invoke fail, jsRuntime is nil")
            return nil
        }
        let paramDict = runtime.jsonValue(param as NSString) as? [AnyHashable: Any]
        return runtime.invoke(event: ev, param: paramDict, callbackID: (callbackID.stringValue), extra: nil, isNewBridge: false) as? String
    }
    
    @objc func publish(_ ev: String, _ param: String, _ callbackID: String)
    {
        guard let runtime = self.jsRuntime else {
            OPJSEventHandlers.logger.error("ttjscore publish fail, jsRuntime is nil")
            return
        }
        guard let delegate = runtime.delegate else {
            OPJSEventHandlers.logger.error("ttjscore publish fail, delegate is nil")
            return
        }

        let webviewIDs: NSString = callbackID as NSString
        // string -> array
        let appPageIDs: [NSNumber]? = webviewIDs.jsonValue() as? [NSNumber]
        // string -> dictionary
        let paramDict = runtime.jsonValue(param as NSString) as? [AnyHashable: Any]
        delegate.runtimePublish?(ev, param: paramDict, appPageIDs: appPageIDs, useNewPublish: false)
    }
    
    @objc func call(_ ev: String, _ param: [AnyHashable: Any], _ callbackID: NSNumber) -> NSDictionary?
    {
        guard let runtime = self.jsRuntime else {
            OPJSEventHandlers.logger.error("ttjscore call fail, jsRuntime is nil")
            return nil
        }
        var paramsDic = param
        paramsDic["_bdp_arraybuffer_param_"] = true
        return runtime.call(event: ev, param: paramsDic, callbackID: callbackID)
    }
    
    @objc func onDocumentReady() {
        guard let runtime = self.jsRuntime else {
            OPJSEventHandlers.logger.error("ttjscore onDocumentReady fail, jsRuntime is nil")
            return
        }
        guard let delegate = runtime.delegate else {
            OPJSEventHandlers.logger.error("ttjscore onDocumentReady fail, delegate is nil")
            return
        }
        delegate.runtimeOnDocumentReady?()
    }
    
    @objc func setTimer(_ type: String, _ functionID: Int, _ delay: Int)
    {
        guard let runtime = self.jsRuntime else {
            OPJSEventHandlers.logger.error("ttjscore setTimer fail, jsRuntime is nil")
            return
        }
        runtime.timerModule.setTimer(type: type, functionID: functionID, delay: delay)
    }

    @objc func clearTimer(_ type: String, _ functionID: Int) {
        guard let runtime = self.jsRuntime else {
            OPJSEventHandlers.logger.error("ttjscore clearTimer fail, jsRuntime is nil")
            return
        }
        runtime.timerModule.clearTimer(type: type, functionID: functionID)
    }
}
