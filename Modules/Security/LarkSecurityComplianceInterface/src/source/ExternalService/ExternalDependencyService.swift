//
//  ExternalDependencyService.swift
//  LarkSecurityComplianceInterface
//
//  Created by ByteDance on 2023/9/11.
//

import Foundation

public protocol ExternalDependencyService {
    var leanModeService: LeanModeSecurityService { get }
    var windowService: WindowService { get }
}
