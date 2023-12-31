//
//  BTDDUIPlugin.swift
//  SKBitable
//
//  Created by X-MAN on 2023/4/12.
//

import Foundation
import SKFoundation
import SKCommon
import LarkWebViewContainer

final class BTDDUIService: BaseJSService {
    
    var channel: BTDDUIChannel?
    var context: BTDDUIContext?
    
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
}

extension BTDDUIService: JSServiceHandler {
    
    func handle(params: [String : Any], serviceName: String) {
        self.handle(params: params, serviceName: serviceName, callback: nil)
    }
    
    var handleServices: [DocsJSService] {
        return [.dduiService]
    }
    
    func handle(params: [String : Any], serviceName: String, callback: APICallbackProtocol?) {
        guard let model = BTDDUIBaseModel.deserialize(from: params) else {
            DocsLogger.btError("[BTDDUIService] prarms is invalid")
            return
        }
        guard let callbackId = model.callback, !callbackId.isEmpty else {
            DocsLogger.btError("[BTDDUIService] prarms does not contain callback")
            return
        }
        if context == nil || channel == nil {
            let context = BTDDUIContext(id: UUID().uuidString, uiConfig: ui, modelConfig: self.model, navigator: navigator, callbackId: callbackId)
            self.context = context
            self.channel = BTDDUIChannel(context: context)
        }
        let permissionObj = BasePermissionObj.parse(params)
        let baseToken = params["baseId"] as? String ?? ""
        let baseContext = BaseContextImpl(baseToken: baseToken, service: self, permissionObj: permissionObj, from: "ddui")
        self.channel?.handle(data: model, baseContext: baseContext)
    }
}

extension BTDDUIService: BrowserViewLifeCycleEvent {
    
    func browserWillRerender() {
        self.channel?.clearAll()
        self.channel = nil
        self.context = nil
    }
    
    func browserTerminate() {
        self.channel?.clearAll()
        self.channel = nil
        self.context = nil
    }
}

extension BTDDUIService: BaseContextService {
    
}
