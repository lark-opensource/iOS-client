//
//  LeanModeSecurityService.swift
//  LarkSecurityComplianceInterface
//
//  Created by ByteDance on 2023/9/11.
//

import Foundation
import RxSwift

public struct LeanModeLockScreenInfo {
    public let encyptPinCode: String?
    public let isActive: Bool
    public let updateTime: Int64
    
    public init(encyptPinCode: String?, isActive: Bool, updateTime: Int64) {
        self.encyptPinCode = encyptPinCode
        self.isActive = isActive
        self.updateTime = updateTime
    }
}

public protocol LeanModeSecurityService {
    var beforeExit: Observable<Void> { get }
    var lockScreenStatus: Observable<LeanModeLockScreenInfo> { get }
    func canUseLeanMode() -> Bool
    func patchLockScreenConfig(password: String?, isEnabled: Bool?) -> Observable<Bool>
    func leanModeLockScreenInfo() -> LeanModeLockScreenInfo?
    func updateLeanModeStatusAndAuthority()
    func openLeanModeStatus()
}
