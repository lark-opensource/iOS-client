//
//  OPBlockGuideInfoLoadTaskDelegate.swift
//  OPBlock
//
//  Created by yinyuan on 2021/3/11.
//

import Foundation
import OPSDK
import OPBlockInterface

class OPBlockGuideInfoLoadTaskInput: OPTaskInput {
    
    public let containerContext: OPContainerContext
    
    public let serviceContainer: OPBlockServiceContainer
    
    required public init(containerContext: OPContainerContext,
                         serviceContainer: OPBlockServiceContainer) {
        self.containerContext = containerContext
        self.serviceContainer = serviceContainer
        super.init()
    }
}

class OPBlockGuideInfoLoadTaskOutput: OPTaskOutput {
    
}
