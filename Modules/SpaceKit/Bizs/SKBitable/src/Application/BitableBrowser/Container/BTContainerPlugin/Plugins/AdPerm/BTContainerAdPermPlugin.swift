//
//  BTContainerAdPermPlugin.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/14.
//

import SKFoundation
import SKUIKit
import SKCommon
import LarkUIKit
import EENavigator
import SKInfra

class BTContainerAdPermPlugin: BTContainerBasePlugin {
    
    private weak var adPermVC: BitableAdPermSettingVC?
    
    private weak var listener: BitableAdPermissionSettingListener?
    
    func showBitableAdvancedPermissionsSettingVC(data: BitableBridgeData, listener: BitableAdPermissionSettingListener?) {
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        guard let browserViewController = service.browserViewController else {
            DocsLogger.error("invalid browserViewController")
            return
        }
        guard let docsInfo = browserViewController.docsInfo else {
            DocsLogger.error("invalid docsInfo")
            return
        }
        guard let hostView = browserViewController.view else {
            DocsLogger.error("invalid hostView")
            return
        }
        guard let currentTopMost = UIViewController.docs.topMost(of: browserViewController) else {
            DocsLogger.error("invalid currentTopMost")
            return
        }
        let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)
        let publicPermissionMeta = permissionManager?.getPublicPermissionMeta(token: docsInfo.objToken)
        let userPermissions = permissionManager?.getUserPermissions(for: docsInfo.objToken)
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
            delegate: self,
            needCloseBarItem: isIPad,
            permStatistics: permStatistics
        )
        vc.watermarkConfig.needAddWatermark = docsInfo.shouldShowWatermark
        if isIPad {
            let navVC = LkNavigationController(rootViewController: vc)
            navVC.modalPresentationStyle = .formSheet
            Navigator.shared.present(navVC, from: currentTopMost, animated: true)
        } else {
            Navigator.shared.push(vc, from: currentTopMost)
        }
        adPermVC = vc
        self.listener = listener
    }
    
    func handleShowProModel(_ params: [String: Any]) {
        // 目前只有独立bitable才能打开高级权限设置页面，因此这里读取 hostBrowserInfo 即可
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        guard let browserViewController = service.browserViewController else {
            DocsLogger.error("invalid browserViewController")
            return
        }
        guard let docsInfo = browserViewController.docsInfo else {
            DocsLogger.error("invalid docsInfo")
            return
        }
        guard let hostView = browserViewController.view else {
            DocsLogger.error("invalid hostView")
            return
        }
        guard let currentTopMost = UIViewController.docs.topMost(of: browserViewController) else {
            DocsLogger.error("invalid currentTopMost")
            return
        }
        do {
            DocsLogger.info("[BAP] handleShowProModel")
            
            guard let proInfoDict = params["proInfo"] as? [String: Any] else {
                DocsLogger.error("[BAP] handleShowProModel proInfo is missing")
                return
            }
            let bridgeData = try CodableUtility.decode(BitableBridgeData.self, withJSONObject: proInfoDict)
            let openDefaultRole = params["openDefaultRole"] as? Bool ?? false
            
            guard PermissionManager.getUserAdPermVisibility(for: docsInfo, isPro: bridgeData.isPro) else {
                DocsLogger.error("[BAP] ad perm setting is not available for current user")
                return
            }

            let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)
            let publicPermissionMeta = permissionManager?.getPublicPermissionMeta(token: docsInfo.objToken)
            let userPermissions = permissionManager?.getUserPermissions(for: docsInfo.objToken)
            
            
            
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
                bridgeData: bridgeData,
                delegate: self,
                needCloseBarItem: isIPad,
                permStatistics: permStatistics,
                openDefaultRole: openDefaultRole
            )
            vc.watermarkConfig.needAddWatermark = docsInfo.shouldShowWatermark
            if isIPad {
                let navVC = LkNavigationController(rootViewController: vc)
                navVC.modalPresentationStyle = .formSheet
                Navigator.shared.present(navVC, from: currentTopMost, animated: true)
            } else {
                Navigator.shared.push(vc, from: currentTopMost)
            }
            adPermVC = vc
        } catch {
            DocsLogger.error("[BAP] BitableBridgeData decode error: \(error)")
            return
        }
    }
    
    func handleAdPermUpdateCompletion(params: [String: Any]) {
        if UserScopeNoChangeFG.ZYS.baseAdPermRoleInheritance {
            guard let vc = adPermVC, vc.delegate === self else {
                return
            }
            vc.handleAdPermUpdateCompletion(params)
            return
        }
        self.adPermVC?.handleAdPermUpdateCompletion(params)
    }
    
    func hideAdPermVCIfNeeded() {
        guard let adPermVC = adPermVC else {
            return
        }
        if let navigationController = adPermVC.navigationController {
            if navigationController.isBeingPresented == true {
                navigationController.dismiss(animated: false)
            } else {
                adPermVC.popSelf()
            }
        }
    }
}

extension BTContainerAdPermPlugin: BitableAdPermSettingVCDelegate {
    var jsService: SKExecJSFuncService? {
        service?.browserViewController?.editor.jsEngine
    }
    
    func bitableAdPermBridgeDataDidChange(_ vc: BitableAdPermSettingVC, data: BitableBridgeData) {
        listener?.onBitableAdPermBridgeDataChange(data)
    }
}
