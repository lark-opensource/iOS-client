//
//  EMMDebugService.swift
//  LarkEMM
//
//  Created by qingchun on 2022/10/13.
//

import Foundation
import RxSwift
import LarkSecurityComplianceInfra
import LarkContainer
import LarkFoundation

public protocol EMMDebugService: UserResolverWrapper {
    func sendScreenProtectionBot()
    func setScreenProtection(_ biz: ScreenProtectionBiz, enabled: Bool) throws
    
    var intergrateThirdEMMStateOnDisk: Int { get }
    var isIntegrateThirdEMMInMemory: Bool? { get }
}

public final class EMMDebugServiceImp: EMMDebugService {
    
    public let userResolver: LarkContainer.UserResolver
    
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    
    public func sendScreenProtectionBot() {
        
    }

    public func setScreenProtection(_ biz: ScreenProtectionBiz, enabled: Bool) throws {
        let service = try userResolver.resolve(assert: ScreenProtectionService.self)
        try service.setScreenProtection(biz, enabled: enabled)
    }
    
    public var intergrateThirdEMMStateOnDisk: Int {
        let scKeyValueStorage = SCKeyValue.globalUserDefault()
        let otherEMMIntergrateState: Int = scKeyValueStorage.value(forKey: "LarkEMM_intergrateOtherEMM_" + Utils.appVersion) ?? 0
        return otherEMMIntergrateState
    }
    
    public var isIntegrateThirdEMMInMemory: Bool? {
        return EMMConfigImp.isIntergrateOtherEMM
    }
    
}
