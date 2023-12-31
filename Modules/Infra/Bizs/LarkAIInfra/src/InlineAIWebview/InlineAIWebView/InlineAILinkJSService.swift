//
//  InlineAILinkJSService.swift
//  LarkAIInfra
//
//  Created by huayufan on 2023/11/1.
//  


import UIKit
import LarkWebViewContainer

class InlineAILinkJSService: InlineAIJSServiceProtocol {

    weak var webView: InlineAIWebView?
    
    weak var delegate: AIWebAPIHandlerDelegate?

    init(webView: InlineAIWebView?, delegate: AIWebAPIHandlerDelegate?) {
        self.webView = webView
        self.delegate = delegate
    }
    
    var handleServices: [InlineAIJSService] {
        return [.openLink]
    }

    func handle(params: [String: Any], serviceName: InlineAIJSService, callback: APICallbackProtocol?) {
        
        switch serviceName {
        case .openLink:
            guard let url = params["url"] as? String else {
                LarkInlineAILogger.error("open url is nil")
                return
            }
            self.delegate?.handle(.openURL(url))
        default:
            break
        }
    }
}
