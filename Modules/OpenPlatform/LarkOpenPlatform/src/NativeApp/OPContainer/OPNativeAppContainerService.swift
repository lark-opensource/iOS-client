//
//  OPNativeAppContainerService.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2022/12/28.
//

import Foundation
import OPSDK

public class OPNativeAppContainerService: OPContainerServiceProtocol {
    
    public let appTypeAbility: OPAppTypeAbilityProtocol = NativeAppTypeAbility()
    
    public init() {
        
    }
}
