//
//  ExternalDependencyImp.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/9/11.
//

import Foundation
import LarkLeanMode
import LarkContainer
import LarkSecurityComplianceInterface
import RxSwift
import LarkAccountInterface

class ExternalDependencyImp: ExternalDependencyService {
    let windowService: WindowService
    let userResolver: UserResolver
    let leanModeExternalService: LeanModeService
    let userService: PassportUserService
    
    init(resolver: UserResolver) throws {
        self.userResolver = resolver
        leanModeExternalService = try resolver.resolve(assert: LeanModeService.self)
        windowService = try resolver.resolve(assert: WindowService.self)
        userService = try resolver.resolve(assert: PassportUserService.self)
    }
    
    var leanModeService: LeanModeSecurityService {
        return self
    }
}
