//
//  WASimpleContainerBridgeService.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/19.
//

import Foundation

public class WASimpleContainerBridgeService: WASimpleBridgeService  {
    
    public override var serviceType: WABridgeServiceType {
        .UI
    }
    
    public private(set) weak var container: WAContainer?
    required init(bridge: WABridge?,
         context: WABridgeServiceContext,
         container: WAContainer) {
        super.init(bridge: bridge, context: context)
        self.container = container
    }
}
