//
//  ClosePageService.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/19.
//

import Foundation

class ClosePageService: WASimpleContainerBridgeService {
    
    override var name: WABridgeName {
        .closePage
    }
    
    override func handle(invocation: WABridgeInvocation) {
        self.container?.hostVC?.closePage()
    }
}
