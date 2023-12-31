//
//  SSRLoadingService.swift
//  SKBrowser
//
//  Created by lijuyou on 2023/5/24.
//  


import Foundation
import SKCommon
import SKFoundation

protocol SSRLoadingServiceDelegate: AnyObject {
    func onHideLoading()
}


final class SSRLoadingService: BaseJSService {
    weak var delegate: SSRLoadingServiceDelegate?
}

extension SSRLoadingService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.utilHideLoading]
    }

    public func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.utilHideLoading.rawValue:
            hidLoading(params: params)
        default:
            spaceAssertionFailure()
        }
    }
    
    func hidLoading(params: [String: Any]) {
        DocsLogger.info("[ssr] hideLoading", extraInfo: params, component: LogComponents.ssrWebView)
        delegate?.onHideLoading()
    }
    
   
}
