//
//  OPSDKConfigInjector.swift
//  EEMicroAppSDK
//
//  Created by 尹清正 on 2021/3/18.
//

import Foundation
import OPSDK
import TTMicroApp
import OPDynamicComponent

/// 该类负责将EMA模块中获取配置的能力注入到OPSDK中
@objcMembers
public final class OPSDKConfigInjector: NSObject {

    /// 是否已经进行过了注入(仅能注入一次)
    static var configInjected = false

    public static func inject() {
        guard !configInjected else {
            return
        }
        configInjected = true

        /// 注入获取当前是否为Debug模式的能力
        OPSDKConfigProvider.isOPDebugAvailableBlock = { OPDebugFeatureGating.debugAvailable() }

        /// 注入获取下发配置的能力
        ///
        /// 注入不是长久之计，待 ECOConfig Stage2 完成后,应当改为直接依赖 ECOConfig
        /// 此依赖是干净的，不会引入 EEMicroAppSDK
        OPSDKConfigProvider.configProvider = {
            return EMAAppEngine.current()?.configManager?.minaConfig.getDictionaryValue(for: $0)
        }

        /// 注入获取本地存储管理工具
        OPSDKConfigProvider.kvStorageProvider = { type in
            if let localFileManager = BDPModuleManager(of: type).resolveModule(with: BDPStorageModuleProtocol.self) as? BDPStorageModuleProtocol {
                return localFileManager.sharedLocalFileManager().kvStorage
            }
            return nil
        }

        OPSDKConfigProvider.silenceUpdater = { type in
            guard let silenceUpdater = EMAPackagePreloadFactory.createPackagePreload(scene: .silence, appType: type) as? OPPackageSilenceUpdateProtocol else {
                return nil
            }
            return silenceUpdater
        }
    }
}
@objcMembers
public final class OPDynamicComponentBridge: NSObject {
    public static func cleanComponents() {
        OPDynamicComponentManager.sharedInstance.cleanDynamicCompoments()
    }
}

/// 该类负责将EMA模块中获取配置的能力注入到TTMicroApp中
@objcMembers
public final class OPTTMicroAppInjector: NSObject {
    /// 是否已经进行过了注入(仅能注入一次)
    static var configInjected = false

    public static func inject() {
        guard !configInjected else {
            return
        }
        configInjected = true

        OPTTMicroAppConfigProvider.dynamicComponentManagerProvider = {
            return OPDynamicComponentManager.sharedInstance
        }
    }
}
