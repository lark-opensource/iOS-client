//
//  ClearWarmCacheRecoveryAction.swift
//  OPGadget
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import OPSDK

/// 清理当前小程序的热缓存
/// 使用异步的方式执行
class ClearWarmCacheRecoveryAction: RecoveryAction {

    func executeAction(with context: RecoveryContext) {
        guard let uniqueID = context.uniqueID else {
            GadgetRecoveryLogger.logger.error("ClearWarmCacheRecoveryAction: can not get uniqueID from RecoveryContext")
            return
        }
        guard let gadgetContainer = OPApplicationService.current.getContainer(uniuqeID: uniqueID) as? OPGadgetContainer else {
            GadgetRecoveryLogger.logger.error("ClearWarmCacheRecoveryAction: can not get container from uniqueID: \(uniqueID.fullString)")
            return
        }

        gadgetContainer.setNeedsCleanWarmCacheWhenClose(true)
    }

}


fileprivate var needsCleanSelfWarmCacheWhenCloseStoreKey: Void? = nil
extension OPGadgetContainer {

    /// 设置小程序是否需要在关闭时清理自己的热缓存
    fileprivate func setNeedsCleanWarmCacheWhenClose(_ needsClean: Bool = true) {
        needsCleanSelfWarmCacheWhenClose = needsClean
    }

    /// 在小程序关闭时按需清理该小程序的热缓存，该方法应该在小程序关闭时调用
    func cleanWarmCacheIfNeeded() {
        if !needsCleanSelfWarmCacheWhenClose {
            return
        }

        let uniqueID = self.containerContext.uniqueID
        GadgetRecoveryActionUtil.clearWarmCache(for: uniqueID)
        setNeedsCleanWarmCacheWhenClose(false)
    }

    /// 记录在小程序关闭时是否需要进行本小程序的热缓存的清理
    fileprivate var needsCleanSelfWarmCacheWhenClose: Bool {
        get {
            (objc_getAssociatedObject(self, &needsCleanSelfWarmCacheWhenCloseStoreKey) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, &needsCleanSelfWarmCacheWhenCloseStoreKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}
