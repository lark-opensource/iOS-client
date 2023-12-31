//
//  SecLabelApprovalBridgeHandler.swift
//  SKCommon
//
//  Created by peilongfei on 2023/5/10.
//  


import BDXBridgeKit
import BDXServiceCenter
import SKFoundation
import SKResource
import SKUIKit
import LarkUIKit
import UniverseDesignColor
import UniverseDesignDialog
import BDXBridgeKit
import LarkReleaseConfig
import LarkLocalizations
import EENavigator
import SKInfra
import SwiftyJSON
import SpaceInterface

class SecLabelApprovalBridgeHandler: NSObject, BridgeHandler {

    let methodName = "ccm.permission.secLabelApproval"
    let handler: BDXLynxBridgeHandler

    init(hostController: UIViewController, followAPIDelegate: BrowserVCFollowDelegate?) {
        handler = { [weak hostController, followAPIDelegate] _, _, params, callback in
            guard let token = params?["token"] as? String,
            let type = params?["type"] as? Int,
            let originalSecLabelDic = params?["originalSecLabel"],
            let targetSecLabelDic = params?["targetSecLabel"],
            let secLabelApprovalDefDic = params?["secLabelApprovalDef"] else {
                DocsLogger.error("adjustSettingsCallback: no params")
                return
            }
            let originalSecLabel = SecretLevelLabel(json: JSON(originalSecLabelDic))
            let targetSecLabel = SecretLevelLabel(json: JSON(targetSecLabelDic))
            let secLabelApprovalDef = SecretLevelApprovalDef(json: JSON(secLabelApprovalDefDic))
            let hostVC = hostController?.presentingViewController
            let followDelegate = followAPIDelegate
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_500) {
                Self.showSecretModifyOriginalViewController(token: token, type: type, originalSecLabel: originalSecLabel, targetSecLabel: targetSecLabel, secLabelApprovalDef: secLabelApprovalDef, wikiToken: nil, hostController: hostVC, followAPIDelegate: followDelegate)
            }
            DocsLogger.info("handle ccm.permission.secLabelApproval")
            callback(BDXBridgeStatusCode.succeeded.rawValue, nil)
        }
    }

    private static func showSecretModifyOriginalViewController(token: String,
                                                        type: Int,
                                                        originalSecLabel: SecretLevelLabel,
                                                        targetSecLabel: SecretLevelLabel,
                                                        secLabelApprovalDef: SecretLevelApprovalDef,
                                                        wikiToken: String?,
                                                        hostController: UIViewController?,
                                                        followAPIDelegate: BrowserVCFollowDelegate?) {
        let originalLevel = SecretLevel(label: originalSecLabel)
        let viewModel: SecretModifyViewModel = SecretModifyViewModel(approvalType: .NoRepeatedApproval,
                                                                     originalLevel: originalLevel,
                                                                     label: targetSecLabel,
                                                                     wikiToken: wikiToken,
                                                                     token: token,
                                                                     type: type,
                                                                     approvalDef: secLabelApprovalDef,
                                                                     approvalList: nil,
                                                                     permStatistic: nil,
                                                                     followAPIDelegate: followAPIDelegate
        )
        guard let hostController = hostController else { return }
        let isIPad = SKDisplay.pad && hostController.isMyWindowRegularSize()
        if isIPad {
            let viewController = IpadSecretModifyOriginalViewController(viewModel: viewModel)
            viewController.didSubmitApproval = { (hostVC, viewModel) in
                Self.didSubmitApproval(hostVC, viewModel: viewModel)
            }
            viewController.hostVC = hostController
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .formSheet
            Navigator.shared.present(nav, from: hostController)
        } else {
            let viewController = SecretModifyOriginalViewController(viewModel: viewModel)
            viewController.didSubmitApproval = { (hostVC, viewModel) in
                Self.didSubmitApproval(hostVC, viewModel: viewModel)
            }
            viewController.hostVC = hostController
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .overFullScreen
            nav.transitioningDelegate = viewController.panelTransitioningDelegate
            Navigator.shared.present(nav, from: hostController)
        }
    }


}

extension SecLabelApprovalBridgeHandler {

    static func didSubmitApproval(_ hostVC: UIViewController?, viewModel: SecretModifyViewModel) {
        guard let topVC = hostVC else {
            DocsLogger.error("topVC is nil", component: LogComponents.comment)
            return
        }
        viewModel.reportCcmPermissionSecurityDemotionResultView(success: true)
        let dialog = SecretApprovalDialog.sendApprovaSuccessDialog {
            Self.showApprovalCenter(topVC: topVC, viewModel: viewModel)
            viewModel.reportCcmPermissionSecurityDemotionResultClick(click: "view_checking")
        } define: {
            viewModel.reportCcmPermissionSecurityDemotionResultClick(click: "known")
        }
        topVC.present(dialog, animated: true, completion: nil)
    }

    private static func showApprovalCenter(topVC: UIViewController, viewModel: SecretModifyViewModel) {
        guard let config = SettingConfig.approveRecordProcessUrlConfig else {
            DocsLogger.error("config is nil")
            return
        }
        guard let instanceId = viewModel.instanceCode else {
            DocsLogger.error("instanceId is nil")
            return
        }
        let urlString = config.url + instanceId
        guard let url = URL(string: urlString) else {
            DocsLogger.error("url is nil")
            return
        }
        if let followAPIDelegate = viewModel.followAPIDelegate {
            followAPIDelegate.follow(onOperate: .vcOperation(value: .setFloatingWindow(getFromVCHandler: { from in
                guard let from else { return }
                Navigator.shared.push(url, from: from)
            })))
        } else {
            Navigator.shared.push(url, from: topVC)
        }
    }
}
