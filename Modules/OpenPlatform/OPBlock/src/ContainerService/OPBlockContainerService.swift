//
//  OPBlockContainerService.swift
//  OPBlock
//
//  Created by yinyuan on 2020/12/17.
//

import Foundation
import OPSDK

public final class OPBlockContainerService: OPContainerServiceProtocol {
    
    public let appTypeAbility: OPAppTypeAbilityProtocol = OPBlockTypeAbility()
    
    public init() {
        
    }
}
