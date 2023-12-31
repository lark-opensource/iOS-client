//
//  GadgetRecoveryResponderService.swift
//  OPGadget
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import OPSDK

/// 用于获取特定Scene对应的触发时需要额外做的响应
struct GadgetRecoveryResponderService {

    static func getGadgetRecoveryResponder(for context: RecoveryContext) -> GadgetRecoveryResponder? {
        switch context.recoveryScene?.value {
        case RecoveryScene.gadgetPageCrashOverload.value:
            return PageCrashResponder()
        case RecoveryScene.gadgetFailToLoad.value:
            return FailToLoadResponder()
        case RecoveryScene.gadgetRuntimeFail.value:
            return RuntimeFailResponder()
        case RecoveryScene.gadgetReloadManually.value:
            return ManuallyRefreshResponder()
        default:
            return nil
        }
    }
    
    
    /// V2版本统一错误responder映射器
    /// - Parameter context: 错误上下文
    /// - Returns: 错误响应对象
    static func getGadgetUnifyErrorResponder(for context: RecoveryContext) -> GadgetRecoveryResponder? {
        switch context.recoveryScene?.value {
        case RecoveryScene.gadgetPageCrashOverload.value:
            return PageCrashResponder()
        case RecoveryScene.gadgetFailToLoad.value,RecoveryScene.gadgetRuntimeFail.value:
            return UniversalLoadErrorResponder()
        case RecoveryScene.gadgetReloadManually.value:
            return ManuallyRefreshResponder()
        default:
            return nil
        }
    }

}
