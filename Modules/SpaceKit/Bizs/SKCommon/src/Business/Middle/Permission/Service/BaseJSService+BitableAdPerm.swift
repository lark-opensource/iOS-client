//
//  JSService+BitableAdPerm.swift
//  SKCommon
//
//  Created by zhysan on 2023/10/8.
//

import SKFoundation
import SKUIKit
import SKInfra
import EENavigator
import LarkUIKit

private class WeakWrapper<T: AnyObject>: NSObject {
    private weak var _object: T?

    var object: T? {
        return _object
    }

    init(with object: T?) {
        _object = object
    }
}

// 即将删除的代码，转移到 SKBitable，暂时需要兼容线上逻辑
@available(*, deprecated, message: "This method is deprecated")
public extension BaseJSService {
    
    private struct AssociatedKey {
        static var adPermVCKey: UInt8 = 0
    }
    
    private var baseAdPermSettingVC: BitableAdPermSettingVC? { // 即将被删除
        get {
            let ref = objc_getAssociatedObject(self, &AssociatedKey.adPermVCKey) as? WeakWrapper<BitableAdPermSettingVC>
            return ref?.object
        }
        set {
            let ref = WeakWrapper(with: newValue)
            objc_setAssociatedObject(self, &AssociatedKey.adPermVCKey, ref, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private var topMostVC: UIViewController? {
        guard let currentBrowserVC = navigator?.currentBrowserVC else {
            return nil
        }
        return UIViewController.docs.topMost(of: currentBrowserVC)
    }
    
    // 即将删除的代码，转移到 SKBitable，暂时需要兼容线上逻辑
    // nolint: duplicated_code
    @available(*, deprecated, message: "This method is deprecated")
    func showBitableAdvancedPermissionsSettingVC(_ data: BitableBridgeData, host: BitableAdPermSettingVCDelegate) {
        guard let docsInfo = hostDocsInfo,
              let hostView = ui?.hostView,
        let currentTopMost = topMostVC else {
            return
        }
        guard let permissionManager = DocsContainer.shared.resolve(PermissionManager.self) else {
            return
        }
        let publicPermissionMeta = permissionManager.getPublicPermissionMeta(token: docsInfo.objToken)
        let userPermissions = permissionManager.getUserPermissions(for: docsInfo.objToken)
        let ccmCommonParameters = CcmCommonParameters(fileId: docsInfo.encryptedObjToken,
                                                      fileType: docsInfo.type.name,
                                                      appForm: (docsInfo.isInVideoConference == true) ? "vc" : "none",
                                                      subFileType: docsInfo.fileType,
                                                      module: docsInfo.type.name,
                                                      userPermRole: userPermissions?.permRoleValue,
                                                      userPermissionRawValue: userPermissions?.rawValue,
                                                      userPermission: userPermissions?.reportData,
                                                      publicPermission: publicPermissionMeta?.rawValue)
        let permStatistics = PermissionStatistics(ccmCommonParameters: ccmCommonParameters)

        let isIPad = SKDisplay.pad && hostView.isMyWindowRegularSize()
        
        let vc = BitableAdPermSettingVC(
            docsInfo: docsInfo,
            bridgeData: data,
            delegate: host,
            needCloseBarItem: isIPad,
            permStatistics: permStatistics
        )
        vc.watermarkConfig.needAddWatermark = hostDocsInfo?.shouldShowWatermark ?? true
        if isIPad {
            let navVC = LkNavigationController(rootViewController: vc)
            navVC.modalPresentationStyle = .formSheet
            Navigator.shared.present(navVC, from: currentTopMost, animated: true)
        } else {
            Navigator.shared.push(vc, from: currentTopMost)
        }
        baseAdPermSettingVC = vc
    }
}
