//
//  GadgetRecoveryActionUtil.swift
//  OPGadget
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import OPSDK
import TTMicroApp
import LarkOPInterface
import LarkFeatureGating

struct GadgetRecoveryActionUtil {

    static func clearWarmCache(for uniqueID: OPAppUniqueID) {
        GadgetRecoveryLogger.logger.info("start to execute clearWarmCache for \(uniqueID.fullString)")
        BDPWarmBootManager.shared()?.cleanCache(with: uniqueID)
    }

    /// 强制清理所有的正在运行的小程序的进程
    static func forceClearWarmCache(except uniqueID: OPAppUniqueID) {
        GadgetRecoveryLogger.logger.info("start to execute forceClearWarmCache except \(uniqueID.fullString)")
        guard var allAliveAppUniqueIdSet = BDPWarmBootManager.shared()?.aliveAppUniqueIdSet else {
            GadgetRecoveryLogger.logger.error("can not get aliveAppUniqueIdSet from BDPWarmBootManaget.shared")
            return
        }

        allAliveAppUniqueIdSet.remove(uniqueID)

        for uniqueID in allAliveAppUniqueIdSet {
            BDPWarmBootManager.shared()?.cleanCache(with: uniqueID)
        }
    }

    /// 重置JSSDK相关文件
    static func resetJSSDK() {
        GadgetRecoveryLogger.logger.info("start to execute resetJSSDK")
        BDPVersionManager.resetLocalLibCache()
    }

    /// 在传入的uniqueID对应的小程序处于非活跃状态下时对其热缓存进行清理
    static func clearWarmCacheIfInactive(for uniqueID: OPAppUniqueID) {
        GadgetRecoveryLogger.logger.info("start to execute clearWarmCacheIfInactive")
        let active: Bool
        if let container = OPApplicationService.current.getApplication(appID: uniqueID.appID)?.getContainer(uniqueID: uniqueID) {
            if LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.gadget.fix.backgroundaudio.release"){
                active = container.containerContext.mountState == .mounted
            } else {
                //默认走新逻辑
                active = container.containerContext.mountState == .mounted || !container.containerContext.containerConfig.enableAutoDestroy
            }
        } else if let common = BDPCommonManager.shared()?.getCommonWith(uniqueID) {
            active = common.isActive
        } else {
            active = true
        }

        GadgetRecoveryLogger.logger.info("clearWarmCacheIfInactive: ready to clean. UniqueID: \(uniqueID.fullString), active: \(active)")
        if !active {
            BDPWarmBootManager.shared()?.cleanCache(with: uniqueID)
        }
    }

    /// 对所有非活跃状态下的内存缓存进行清理
    static func clearAllInactiveWarmCache() {
        guard let allAliveAppUniqueIdSet = BDPWarmBootManager.shared()?.aliveAppUniqueIdSet else {
            GadgetRecoveryLogger.logger.error("can not get aliveAppUniqueIdSet from BDPWarmBootManaget.shared")
            return
        }
        GadgetRecoveryLogger.logger.info("start to execute clearAllInactiveWarmCache")

        for uniqueID in allAliveAppUniqueIdSet {
            clearWarmCacheIfInactive(for: uniqueID)
        }
    }

    /// 清理单个小程序的meta与包信息，在清理之前会先强制退掉目标小程序
    static func clearMetaAndPkg(for uniqueID: OPAppUniqueID) {
        GadgetRecoveryLogger.logger.info("start to execute clearMetaAndPkg")
        // 清理之前先清小程序进程
        BDPWarmBootManager.shared()?.cleanCache(with: uniqueID)
        // 清理目标小程序的meta和包信息
        BDPAppLoadManager.shareService().removeAllMetaAndData(with: uniqueID, pkgName: nil)
    }
}
