//
//  BTJSService+permission.swift
//  SKBitable
//
//  Created by chensi(陈思) on 2022/4/19.
//  


import Foundation
import SKCommon
import SKFoundation
import SKUIKit
import EENavigator
import LarkUIKit
import SKInfra

private var hasCopyPermissionKey: UInt8 = 0

extension BTJSService: DocsPermissionEventObserver {
    
    var hasCopyPermissionDeprecated: Bool { // 即将被删除
        get {
            return (objc_getAssociatedObject(self, &hasCopyPermissionKey) as? Bool) ?? ViewCapturePreventer.canCopyDefaultValue
        }
        set {
            objc_setAssociatedObject(self, &hasCopyPermissionKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    // 即将被删除
    func onCopyPermissionUpdated(canCopy: Bool) {
        if UserScopeNoChangeFG.YY.bitableReferPermission {
            return
        }
        hasCopyPermissionDeprecated = canCopy
        cardVC?.allowCapture = canCopy
        cardVC?.updateVisibleCellsCaptureAllowedState() // 手动触发刷新
        
        let maxLinkDepth = BTController.linkedRecordMaxCardLevel // 兜底,避免死循环
        var tempVC: BTController? = cardVC
        var tempDepth = 0
        while let vc = tempVC?.linkedController, tempDepth <= maxLinkDepth { // 递归处理关联卡片
            vc.allowCapture = canCopy
            vc.updateVisibleCellsCaptureAllowedState() // 手动触发刷新
            tempVC = vc
            tempDepth += 1
            DocsLogger.btInfo("[ACTION] set `isCaptureAllowed` -> \(canCopy), depth:\(tempDepth)")
        }
        
        groupStatisticsVC?.setCaptureAllowed(canCopy)
    }
}

extension BTJSService: BitableAdPermSettingVCDelegate {
    var jsService: SKExecJSFuncService? {
        model?.jsEngine
    }
}
