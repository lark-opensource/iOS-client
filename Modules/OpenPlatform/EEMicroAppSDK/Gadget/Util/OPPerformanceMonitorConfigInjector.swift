//
//  OPPerformanceMonitorConfigInjector.swift
//  EEMicroAppSDK
//
//  Created by liuyou on 2021/4/22.
//

import Foundation
import OPSDK

/// 该类负责将EMA模块中获取配置的能力注入到OPPerformanceMonitorConfigProvider中
@objcMembers
public final class OPPerformanceMonitorConfigInjector: NSObject {

    /// 是否已经进行过了注入(仅能注入一次)
    static var configInjected = false

    public static func inject() {
        guard !configInjected else {
            return
        }
        configInjected = true

        /// 注入获取UserID的能力
        OPPerformanceMonitorConfigProvider.currentUserIDBlock = { EMAAppEngine.current()?.account?.userID }

        /// 注入获取下发配置的能力
        ///
        /// 注入不是长久之计，待 ECOConfig Stage2 完成后,应当改为直接依赖 ECOConfig
        /// 此依赖是干净的，不会引入 EEMicroAppSDK
        OPPerformanceMonitorConfigProvider.configProvider = {
            return EMAAppEngine.current()?.configManager?.minaConfig.getDictionaryValue(for: $0)
        }
    }
}
