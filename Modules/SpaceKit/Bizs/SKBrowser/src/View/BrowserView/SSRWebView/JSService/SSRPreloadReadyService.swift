//
//  SSRPreloadReadyService.swift
//  SKBrowser
//
//  Created by lijuyou on 2023/5/23.
//  


import Foundation
import SKCommon
import SKFoundation
import SKInfra

protocol SSRPreloadReadyServiceDelegate: AnyObject {
    func onSSRTemplatePreloadReady()
}

class SSRPreloadReadyService: BaseJSService {
    weak var delegate: SSRPreloadReadyServiceDelegate?
}

extension SSRPreloadReadyService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.notifyPreloadReady]
    }
    func handle(params: [String: Any], serviceName: String) {
        DocsLogger.info("[ssr] SSRWebview Preload Ready", component: LogComponents.ssrWebView)
        self.delegate?.onSSRTemplatePreloadReady()
       
    }
}
