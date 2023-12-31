//
//  TemplateReadyService.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/16.
//

import Foundation

class TemplateReadyService: WASimpleBridgeService {
    
    override var name: WABridgeName {
        .documentReady
    }
    
    override var serviceType: WABridgeServiceType {
        return .base
    }

    override func handle(invocation: WABridgeInvocation) {
        self.context?.host.loaderAgent?.onTemplateReady()
    }
}
