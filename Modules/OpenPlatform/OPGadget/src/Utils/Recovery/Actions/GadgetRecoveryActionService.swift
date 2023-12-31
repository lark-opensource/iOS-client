//
//  GadgetRecoveryActionService.swift
//  OPGadget
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import OPSDK

/// 默认的小程序action配置的key
fileprivate let defaultActionConfigKey = "default"
/// 触发初级熔断机制时action配置的key
fileprivate let primaryHystrixActionConfigKey = "primaryHystrix"
/// 触发终极熔断机制时action配置的key
fileprivate let finalHystrixActionConfigKey = "finalHystrix"

/// 清理当前小程序热缓存Action的Key
fileprivate let ClearWarmCacheRecoveryActionKey = "ClearWarmCacheRecoveryAction"
/// 清理当前小程序Meta与包信息缓存Action的Key
fileprivate let ClearMetaPkgRecoveryActionKey = "ClearMetaPkgRecoveryAction"
/// 清理所有非活跃小程序(不在前台)热缓存Action的Key
fileprivate let ClearInactiveWarmCacheRecoveryActionKey = "ClearInactiveWarmCacheRecoveryAction"
/// 重制JSSDK缓存Action的Key
fileprivate let ResetJSSDKRecoveryActionKey = "ResetJSSDKRecoveryAction"
/// 清理小程序相关的预加载缓存Action的Key
fileprivate let ClearPreloadCacheRecoveryActionKey = "ClearPreloadCacheRecoveryAction"

struct GadgetRecoveryActionService {

    /// 根据配置获取对应类型的actions组合
    static func getActions(with error: OPError, hystrixType: GadgetRecoveryHystrixType) -> [RecoveryAction] {
        switch hystrixType {
        case .none:
            let monitorID = error.monitorCode.id
            return getActions(configKey: monitorID)
        case .primary:
            return getActions(configKey: primaryHystrixActionConfigKey)
        case .final:
            return getActions(configKey: finalHystrixActionConfigKey)
        }
    }

}

private extension GadgetRecoveryActionService {

    /// 默认的actions
    static var defaultActions: [RecoveryAction] {
        return []
    }

    /// 如果配置中找不到就用线上默认配置，线上默认配置也没有的话就用本地提供的默认值
    static func getActions(configKey: String) -> [RecoveryAction] {
        return tryGetActions(configKey: configKey) ?? tryGetActions(configKey: defaultActionConfigKey) ?? defaultActions
    }

    /// 尝试根据配置的字典key，组合成一组actions
    static func tryGetActions(configKey: String) -> [RecoveryAction]? {
        guard let actionsConfig = GadgetRecoveryConfigProvider.gadgetActionsConfig(for: configKey) else {
            return nil
        }

        var actions = [RecoveryAction]()
        if actionsConfig.contains(ClearWarmCacheRecoveryActionKey) {
            actions.append(ClearWarmCacheRecoveryAction())
        }
        if actionsConfig.contains(ClearMetaPkgRecoveryActionKey) {
            actions.append(ClearMetaPkgRecoveryAction())
        }
        if actionsConfig.contains(ClearInactiveWarmCacheRecoveryActionKey) {
            actions.append(ClearInactiveWarmCacheRecoveryAction())
        }
        if actionsConfig.contains(ResetJSSDKRecoveryActionKey) {
            actions.append(ResetJSSDKRecoveryAction())
        }
        if actionsConfig.contains(ClearPreloadCacheRecoveryActionKey) {
            actions.append(ClearPreloadCacheRecoveryAction())
        }

        return actions

    }
}
