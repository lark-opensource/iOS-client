//
//  OPContainerServiceProtocol.swift
//  OPSDK
//
//  Created by yinyuan on 2020/12/17.
//

import Foundation

/// 一种类型的容器的统一Service
public protocol OPContainerServiceProtocol {
    
    var appTypeAbility: OPAppTypeAbilityProtocol { get }
}
