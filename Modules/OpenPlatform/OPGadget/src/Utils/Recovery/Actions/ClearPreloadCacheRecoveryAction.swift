//
//  ClearPreloadCacheRecoveryAction.swift
//  OPGadget
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import OPSDK
import TTMicroApp

/// 清理小程序的预加载缓存
/// 由于预加载缓存的清理需要在包Meta以及JSSDK清理之后进行，以确保之后新预加载的内容是从新的包或者JSSDK中加载而来的
/// 所以使用异步的方式执行
class ClearPreloadCacheRecoveryAction: RecoveryAction {

    func executeAction(with context: RecoveryContext) {
        guard let gadgetContainer = context.container as? OPGadgetContainer else {
            GadgetRecoveryLogger.logger.error("ClearPreloadCacheRecoveryAction: can not get container from recoveryContext. uniqueID: \(context.uniqueID?.fullString ?? "empty")")
            return
        }

        gadgetContainer.setNeedsClearPreloadCacheWhenClose(true)
    }

}

fileprivate var needsClearPreloadCacheWhenCloseStoreKey: Void? = nil

extension OPGadgetContainer {

    fileprivate func setNeedsClearPreloadCacheWhenClose(_ needsClean: Bool = true) {
        needsClearPreloadCacheWhenClose = needsClean
    }

    /// 在小程序关闭时执行，按照需要决定是否清理预加载缓存
    func clearPreloadCacheIfNeed() {
        if !needsClearPreloadCacheWhenClose {
            return
        }
        let uniqueID = self.containerContext.uniqueID
        GadgetRecoveryLogger.logger.info("start to clear preload cache. UniqueID: \(uniqueID.fullString)")
        // 释放所有为小程序预加载的runtime
        BDPJSRuntimePreloadManager.shared()?.updateReleaseReason("clear_preload_cache")
        BDPJSRuntimePreloadManager.shared()?.releasePreloadRuntimeIfNeed(.gadget)
        // 释放所有预加载的BDPAppPage
        BDPAppPageFactory.releaseAllPreloadedAppPage(withReason: "clear_preload_cache")
        // 释放该小程序内部预加载的BDPAppPage
        if let task = BDPTaskManager.shared()?.getTaskWith(uniqueID) {
            task.pageManager?.releaseAllPreloadAppPage()
        }
        setNeedsClearPreloadCacheWhenClose(false)
    }

    /// 记录在小程序关闭时是否需要执行预加载缓存清理相关的操作
    fileprivate var needsClearPreloadCacheWhenClose: Bool {
        get {
            (objc_getAssociatedObject(self, &needsClearPreloadCacheWhenCloseStoreKey) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, &needsClearPreloadCacheWhenCloseStoreKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}

