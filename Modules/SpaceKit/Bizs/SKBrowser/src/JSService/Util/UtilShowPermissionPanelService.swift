//
//  UtilShowPermissionPanelService.swift
//  SKBrowser
//
//  Created by tanyunpeng on 2023/8/24.
//  


import Foundation
import SKCommon
import SKUIKit
import SKFoundation
import EENavigator
import SpaceInterface
import SKInfra
import LarkUIKit


class UtilShowPermissionPanelService: BaseJSService {}

extension UtilShowPermissionPanelService: DocsJSServiceHandler {
    
    private var currentTopMost: UIViewController? {
        guard let currentBrowserVC = navigator?.currentBrowserVC else {
            return nil
        }
        return UIViewController.docs.topMost(of: currentBrowserVC)
    }
    
    var handleServices: [DocsJSService] {
        return [.permissionPanel]
    }
    
    func handle(params: [String : Any], serviceName: String) {
        if serviceName == DocsJSService.permissionPanel.rawValue {
            showPermissionPanel()
        }
    }

    
    private func showPermissionPanel() {
        guard let docsInfo = hostDocsInfo,
              let hostView = ui?.hostView,
        let currentTopMost = currentTopMost else {
            DocsLogger.error("docsInfo or hostView or currentTopMost nil")
            return
        }
        guard let url = try? HelpCenterURLGenerator.generateURL(article: .dlpBannerHelpCenter).absoluteString else {
            DocsLogger.error("failed to generate helper center URL when showPublicPermissionSettingVC from dlpBannerHelpCenter")
            return
        }
        let publicPermissionMeta = DocsContainer.shared.resolve(PermissionManager.self)?.getPublicPermissionMeta(token: docsInfo.objToken)
        let userPermissions = DocsContainer.shared.resolve(PermissionManager.self)?.getUserPermissions(for: docsInfo.objToken)
        let ccmCommonParameters = CcmCommonParameters(fileId: docsInfo.encryptedObjToken,
                                                      fileType: docsInfo.type.name,
                                                      appForm: (docsInfo.isInVideoConference == true) ? "vc" : "none",
                                                      subFileType: docsInfo.fileType,
                                                      module: docsInfo.type.name,
                                                      userPermRole: userPermissions?.permRoleValue,
                                                      userPermissionRawValue: userPermissions?.rawValue,
                                                      publicPermission: publicPermissionMeta?.rawValue)
        let permStatistics = PermissionStatistics(ccmCommonParameters: ccmCommonParameters)
        let isIPad = SKDisplay.pad && hostView.isMyWindowRegularSize()
        let permissionVC = PublicPermissionViewControllerManager.getPublicPermissionController(docsInfo: docsInfo,
                                                                                               followAPIDelegate: model?.vcFollowDelegate,
                                                                                               isMyWindowRegularSizeInPad: isIPad,
                                                                                               permStatistics: permStatistics,
                                                                                               url: url)
        if isIPad {
            let navVC = LkNavigationController(rootViewController: permissionVC)
            navVC.modalPresentationStyle = .formSheet
            model?.userResolver.navigator.present(navVC, from: currentTopMost, animated: true)
        } else {
            model?.userResolver.navigator.push(permissionVC, from: currentTopMost)
        }
    }
}
