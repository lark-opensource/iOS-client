//
//  OPDiagnoseRunnerValidator.swift
//  OPSDK
//
//  Created by 尹清正 on 2021/2/18.
//

import Foundation

/// 校验器协议，用于校验DiagnoseRunner当前是否为可用状态
public protocol OPDiagnoseRunnerValidator {
    func validate(runner: OPDiagnoseBaseRunner) -> Bool
}

/// 校验器的默认实现
public final class OPDiagnoseRunnerBaseValidator: OPDiagnoseRunnerValidator {
    let currentPermission: OPDiagnoseRunnerPermission

    init() {
        // 判断当前所处的权限环境
        #if DEBUG
        currentPermission = .debug
        #else
        currentPermission = .release
        #endif
    }

    public func validate(runner: OPDiagnoseBaseRunner) -> Bool {
        // 首先要经过OPDebugFeatureGating对新版调试功能的统一控制
        #if ALPHA
        return true
        #endif
        
        if(!OPSDKConfigProvider.isOPDebugAvailable) {
            return false
        }
        // 判断当前所处的权限环境是否允许runner运行
        return currentPermission.include(level: runner.permission)
    }


}
