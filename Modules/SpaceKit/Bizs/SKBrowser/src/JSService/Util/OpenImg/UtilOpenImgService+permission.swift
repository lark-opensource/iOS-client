//
//  UtilOpenImgService+permission.swift
//  SKBrowser
//
//  Created by chensi(陈思) on 2022/5/11.
//  


import Foundation
import SKCommon
import SKFoundation

private var hasCopyPermissionKey: UInt8 = 0

extension UtilOpenImgService: DocsPermissionEventObserver {
    
    var hasCopyPermission: Bool {
        get {
            return (objc_getAssociatedObject(self, &hasCopyPermissionKey) as? Bool) ?? ViewCapturePreventer.canCopyDefaultValue
        }
        set {
            objc_setAssociatedObject(self, &hasCopyPermissionKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    // 显示的是否是当前文档的图片 (非同源synced block不算)
    var isShowCurrentDocsImage: Bool {
        guard let vc = assetBrowserController else { return false }
        if let srcObjToken = vc.currentPhotoData?.srcObjToken, srcObjToken != self.hostDocsInfo?.token {
            return false
        }
        return true
    }
    
    func onCopyPermissionUpdated(canCopy: Bool) {
        hasCopyPermission = canCopy
        if let vc = assetBrowserController {
            if isShowCurrentDocsImage {
                vc.setAllowCapture(canCopy)
            }
        } else {
            DocsLogger.info("UtilOpenImgService: cannot get assetBrowserController")
        }
    }
}
