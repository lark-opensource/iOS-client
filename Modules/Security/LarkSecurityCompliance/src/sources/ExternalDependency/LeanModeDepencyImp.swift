//
//  LeanModeDepencyImp.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/9/12.
//

import Foundation
import LarkSecurityComplianceInterface
import LarkLeanMode
import RxSwift
import LarkAccountInterface

extension ExternalDependencyImp: LeanModeSecurityService {
    var beforeExit: RxSwift.Observable<Void> {
        return leanModeExternalService.beforeExit
    }
    
    var lockScreenStatus: RxSwift.Observable<LarkSecurityComplianceInterface.LeanModeLockScreenInfo> {
        return leanModeExternalService.lockScreenStatus.map({ config in
            return LeanModeLockScreenInfo(encyptPinCode: config.lockScreenPassword, isActive: config.isLockScreenEnabled, updateTime: config.lockScreenCfgUpdatedAtMicroSec)
        })
    }
    
    func canUseLeanMode() -> Bool {
        return leanModeExternalService.currentLeanModeStatusAndAuthority.canUseLeanMode
    }
    
    func patchLockScreenConfig(password: String?, isEnabled: Bool?) -> RxSwift.Observable<Bool> {
        return leanModeExternalService.patchLockScreenConfig(password: password, isEnabled: isEnabled)
            .map({ _ in
                return true
            })
            .catchErrorJustReturn(false)
    }
    
    func leanModeLockScreenInfo() -> LarkSecurityComplianceInterface.LeanModeLockScreenInfo? {
        guard let leanModeInfo = userService.user.leanModeInfo else { return nil }
        return LeanModeLockScreenInfo(encyptPinCode: leanModeInfo.lockScreenPwd ?? "", isActive: leanModeInfo.isLockScreenEnabled, updateTime: leanModeInfo.lockScreenCfgUpdateTime)
    }
    
    func updateLeanModeStatusAndAuthority() {
        let userService = try? userResolver.resolve(assert: PassportUserService.self)
        guard let leanModeInfo = userService?.user.leanModeInfo else {
            return
        }
        let statusAndAuthority = LeanModeStatusAndAuthority(
            deviceHaveAuthority: leanModeInfo.deviceHaveAuthority,
            allDevicesInLeanMode: leanModeInfo.allDevicesInLeanMode,
            canUseLeanMode: leanModeInfo.canUseLeanMode,
            leanModeUpdateTime: leanModeInfo.leanModeCfgUpdateTime,
            lockScreenPassword: leanModeInfo.lockScreenPwd ?? "",
            isLockScreenEnabled: leanModeInfo.isLockScreenEnabled,
            lockScreenUpdateTime: leanModeInfo.lockScreenCfgUpdateTime
        )
        leanModeExternalService.updateLeanModeStatusAndAuthority(statusAndAuthority: statusAndAuthority, scene: .login)
    }
    
    func openLeanModeStatus() {
        leanModeExternalService.openLeanModeStatus()
    }
}
