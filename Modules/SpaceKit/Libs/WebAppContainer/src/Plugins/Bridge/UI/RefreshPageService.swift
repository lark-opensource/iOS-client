//
//  RefreshPageService.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/12/7.
//

import Foundation

class RefreshPageService: WASimpleContainerBridgeService {
    
    override var name: WABridgeName {
        .refreshPage
    }
    
    override func handle(invocation: WABridgeInvocation) {
        self.container?.hostVC?.refreshPage()
    }
}
