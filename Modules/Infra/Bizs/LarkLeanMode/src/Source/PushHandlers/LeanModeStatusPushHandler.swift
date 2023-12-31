//
//  LeanModeStatusPushHandler.swift
//  LarkLeanMode
//
//  Created by 袁平 on 2020/3/6.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer

final class LeanModeStatusPushHandler: UserPushHandler {

    private var leanModeAPI: LeanModeAPI? { try? userResolver.resolve(assert: LeanModeAPI.self) }

    func process(push message: PushLeanModeStatusAndAuthorityResponse) throws {
        let statusAndAuthority = LeanModeStatusAndAuthority(
            deviceHaveAuthority: message.leanModeCfg.deviceHaveAuthority,
            allDevicesInLeanMode: message.leanModeCfg.allDevicesInLeanMode,
            canUseLeanMode: message.leanModeCfg.canUseLeanMode,
            leanModeUpdateTime: message.leanModeCfg.leanModeCfgUpdatedAtMicroSec,
            lockScreenPassword: message.lockScreenCfg.lockScreenPassword,
            isLockScreenEnabled: message.lockScreenCfg.isLockScreenEnabled,
            lockScreenUpdateTime: message.lockScreenCfg.lockScreenCfgUpdatedAtMicroSec
        )
        leanModeAPI?.updateLeanModeStatusAndAuthority(statusAndAuthority: statusAndAuthority, scene: .push)
    }
}
