//
//  ClearInactiveWarmCacheRecoveryAction.swift
//  OPGadget
//
//  Created by liuyou on 2021/5/14.
//

import Foundation

import OPSDK

/// 清理位于后台的小程序热缓存，帮助释放内存空间
class ClearInactiveWarmCacheRecoveryAction: RecoveryAction {

    func executeAction(with context: RecoveryContext) {
        GadgetRecoveryActionUtil.clearAllInactiveWarmCache()
    }

}
