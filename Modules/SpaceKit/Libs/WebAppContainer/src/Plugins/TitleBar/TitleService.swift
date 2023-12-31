//
//  TitleService.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/19.
//

import Foundation


class TitleService: WASimpleContainerBridgeService {
    
    override var name: WABridgeName {
        .setTitle
    }
    
    override func handle(invocation: WABridgeInvocation) {
        guard let newTitle = invocation.params["title"] as? String else {
            return
        }
        self.container?.hostVC?.updateTitle(newTitle)
    }
}
