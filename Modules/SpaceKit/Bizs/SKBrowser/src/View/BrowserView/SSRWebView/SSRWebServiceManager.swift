//
//  SSRWebServiceManager.swift
//  SKBrowser
//
//  Created by lijuyou on 2023/5/23.
//  


import Foundation
import SKCommon
import SKFoundation
import LarkWebViewContainer
import SpaceInterface
import SKInfra

final class SSRWebServiceManager: JSServicesManager {
    
    private var baseServices = [JSServiceHandler]()
    weak var lkwBridge: LarkWebViewBridge?
    var lkwAPIHandler: LarkWebViewAPIHandler?
    
    override func register(handler: JSServiceHandler) -> JSServiceHandler {
        if let lkwAPIHandler = self.lkwAPIHandler {
            handler.handleServices.forEach { jsService in
                lkwBridge?.registerAPIHandler(lkwAPIHandler, name: jsService.rawValue)
            }
        }
        return super.register(handler: handler)
    }
}
