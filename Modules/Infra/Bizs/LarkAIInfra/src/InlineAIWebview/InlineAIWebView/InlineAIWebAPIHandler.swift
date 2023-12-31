//
//  InlineAIWebAPIHandler.swift
//  LarkInlineAI
//
//  Created by GuoXinyi on 2023/5/11.
//

import Foundation
import LarkWebViewContainer

protocol InlineAIJSServiceProtocol {
    var handleServices: [InlineAIJSService] { get }
    func handle(params: [String: Any], serviceName: InlineAIJSService, callback: APICallbackProtocol?)
}

protocol AIWebAPIHandlerDelegate: AnyObject {
    func handle(_ event: InlineAIEvent)
}

class InlineAIWebAPIHandler: WebAPIHandler {
    
    /// 标记是否注册过bridge
    var registered = false
    
    /// webview控制器
    weak var webView: InlineAIWebView?
    
    /// 弱引用LarkWebview Bridge对象
    weak var lkwBridge: LarkWebViewBridge?
    
    weak var delegate: AIWebAPIHandlerDelegate?

    var methods: [String] {
        services.flatMap {
            return $0.handleServices.map { jsService in
                jsService.rawValue
            }
        }
    }
    
    var services: [InlineAIJSServiceProtocol] = []
    
    init(webView: InlineAIWebView, delegate: AIWebAPIHandlerDelegate?) {
        super.init()
        self.webView = webView
        self.lkwBridge = self.webView?.lkwBridge
        self.delegate = delegate
        setupService()
    }
    
    deinit {
        LarkInlineAILogger.info("InlineAIWebAPIHandler deinit")
    }
    
    private func setupService() {
        services = [InlineAIShowContentJSService(webView: webView, delegate: self.delegate),
                    InlineAISelectionMenuJSService(webView: webView, delegate: self.delegate),
                    InlineAILinkJSService(webView: webView, delegate: self.delegate)]
    }
    
    func getServiceInstance<H: InlineAIJSServiceProtocol>(_ service: H.Type) -> H? {
        let service =  services.first { type(of: $0) == service }
        return service as? H
    }
    
    func register() {
        guard registered == false else {
            return
        }
        LarkInlineAILogger.info("[web] begin register")
        methods.forEach {
            LarkInlineAILogger.info("[web] register \($0)")
            self.lkwBridge?.registerAPIHandler(self, name: $0)
        }
        registered = true
    }
    
    override func invoke(with message: APIMessage, webview: LarkWebView, callback: APICallbackProtocol) {
        LarkInlineAILogger.info("[web] invoke: \(message.apiName)")
        let cmd = InlineAIJSService(rawValue: message.apiName)
        self.services.forEach { service in
            if service.handleServices.contains(cmd) {
                service.handle(params: message.data, serviceName: cmd, callback: callback)
            }
        }
    }
}
