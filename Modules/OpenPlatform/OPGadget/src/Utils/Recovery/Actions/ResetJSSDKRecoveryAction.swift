//
//  ResetJSSDKRecoveryAction.swift
//  OPGadget
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import OPSDK

/// 重置JSSDK文件、内存缓存
/// 由于JSSDK文件的删除会影响到小程序的执行，所以使用异步执行的方式
class ResetJSSDKRecoveryAction: RecoveryAction {

    func executeAction(with context: RecoveryContext) {
        guard let uniqueID = context.uniqueID else {
            return
        }
        guard let gadgetContainer = OPApplicationService.current.getContainer(uniuqeID: uniqueID) as? OPGadgetContainer else {
            return
        }

        gadgetContainer.setNeedsResetJSSDKWhenClose(true)
    }

}

fileprivate var needsResetJSSDKWhenCloseStoreKey: Void? = nil
extension OPGadgetContainer {

    /// 设置小程序关闭时是否需要重置JSSDK
    fileprivate func setNeedsResetJSSDKWhenClose(_ needsClean: Bool = true) {
        needsResetJSSDKWhenClose = needsClean
    }

    /// 在小程序关闭时按需执行JSSDK文件的重置，该方法应在小程序关闭时进行调用
    func resetJSSDKIfNeeded() {
        if !needsResetJSSDKWhenClose {
            return
        }

        let uniqueID = self.containerContext.uniqueID
        // 清理小程序进程
        GadgetRecoveryActionUtil.forceClearWarmCache(except: uniqueID)
        // 清理JSSDK文件
        GadgetRecoveryActionUtil.resetJSSDK()
        setNeedsResetJSSDKWhenClose(false)
    }

    /// 记录是否需要在小程序退出时进行JSSDK文件的重置
    fileprivate var needsResetJSSDKWhenClose: Bool {
        get {
            (objc_getAssociatedObject(self, &needsResetJSSDKWhenCloseStoreKey) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, &needsResetJSSDKWhenCloseStoreKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}
