//
//  ClearMetaPkgRecoveryAction.swift
//  OPGadget
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import OPSDK

/// 清理当前小程序的Meta以及代码包
/// 由于在小程序运行中清理Meta与包可能会出现预期之外的错误，所以采用异步清理的方式
/// 该Action只是将needsCleanSelfMetaPkg属性设置为true，真正的清理工作会放到小程序Unmount时执行(needsCleanSelfMetaPkg)
class ClearMetaPkgRecoveryAction: RecoveryAction {

    func executeAction(with context: RecoveryContext) {
        guard let uniqueID = context.uniqueID else {
            GadgetRecoveryLogger.logger.error("ClearMetaPkgRecoveryAction: can not get uniqueID from RecoveryContext")
            return
        }
        guard let gadgetContainer = OPApplicationService.current.getContainer(uniuqeID: uniqueID) as? OPGadgetContainer else {
            GadgetRecoveryLogger.logger.error("ClearMetaPkgRecoveryAction: can not get container from uniqueID: \(uniqueID.fullString)")
            return
        }

        gadgetContainer.setNeedsCleanMetaPkgWhenClose(true)
    }

}


fileprivate var needsCleanSelfMetaPkgWhenCloseStoreKey: Void? = nil
extension OPGadgetContainer {

    /// 设置小程序关闭时是否需要执行Meta与包的清理工作
    fileprivate func setNeedsCleanMetaPkgWhenClose(_ needsClean: Bool = true) {
        needsCleanSelfMetaPkgWhenClose = needsClean
    }

    /// 按需执行包以及Meta的清理工作，会在小程序关闭时执行
    func cleanMetaPkgIfNeeded() {
        if !needsCleanSelfMetaPkgWhenClose {
            return
        }

        let uniqueID = self.containerContext.uniqueID
        GadgetRecoveryActionUtil.clearMetaAndPkg(for: uniqueID)
        setNeedsCleanMetaPkgWhenClose(false)
    }

    /// 记录是否需要在小程序关闭时进行该小程序包以及meta信息的清理工作
    fileprivate var needsCleanSelfMetaPkgWhenClose: Bool {
        get {
            (objc_getAssociatedObject(self, &needsCleanSelfMetaPkgWhenCloseStoreKey) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, &needsCleanSelfMetaPkgWhenCloseStoreKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}
