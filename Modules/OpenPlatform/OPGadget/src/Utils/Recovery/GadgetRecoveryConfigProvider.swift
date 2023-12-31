//
//  GadgetRecoveryConfigProvider.swift
//  OPGadget
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import OPSDK
import LarkLocalizations

@objcMembers public final class GadgetRecoveryConfigProvider: NSObject {
    /// 容器错误恢复配置字典
    static var recoveryConfig: [AnyHashable: Any]? {
        let appearanceConfig = OPSDKConfigProvider.configProvider?("appearanceConfig") as? [AnyHashable: Any]
        return appearanceConfig.parseValue(key: "recovery")
    }

    /// 获取小程序错误恢复的action配置字典
    static var gadgetRecoveryActionsConfig: [AnyHashable: Any]? {
        recoveryConfig.parseValue(key: "gadget_recovery_actions")
    }


    /// 根据error的monitorID获取对应的Actions组合
    static func gadgetActionsConfig(for configKey: String) -> [String]? {
        gadgetRecoveryActionsConfig.parseValue(key: configKey)
    }

    /// 根据monitorDomain获取对应的错误码DomainCode
    static func gadgetRecoveryMonitorDomainCode(with monitorDomain: String) -> String? {
        let monitorDomainCodeConfig: [AnyHashable: Any]? = recoveryConfig.parseValue(key: "gadget_recovery_domain_code")
        return monitorDomainCodeConfig.parseValue(key: monitorDomain)
    }

    /// 获取小程序容器错误恢复熔断机制配置
    static var gadgetRecoveryHystrixConfig: GadgetRecoveryHystrixConfig {
        let gadgetHystrixConfig: [AnyHashable: Any]? = recoveryConfig.parseValue(key: "gadget_recovery_hystrix")
        let primary: [AnyHashable: Any]? = gadgetHystrixConfig.parseValue(key: "primary")
        let final: [AnyHashable: Any]? = gadgetHystrixConfig.parseValue(key: "final")

        guard let primarySingle: Int = primary.parseValue(key: "single"),
              let primaryGlobal: Int = primary.parseValue(key: "global"),
              let finalSingle: Int = final.parseValue(key: "single"),
              let finalGlobal: Int = final.parseValue(key: "global") else {
            return .default
        }

        return .init(
            primarySingle: primarySingle,
            primaryGlobal: primaryGlobal,
            finalSingle: finalSingle,
            finalGlobal: finalGlobal
        )
    }
}

/// 从字典中取指定类型数据的便捷方法
fileprivate extension Swift.Optional where Wrapped == Dictionary<AnyHashable, Any> {

    func parseValue<Result>(key: AnyHashable, defaultValue: Result) -> Result {
        return (self?[key] as? Result) ?? defaultValue
    }

    func parseValue<Result>(key: AnyHashable) -> Result? {
        return (self?[key] as? Result)
    }

}
