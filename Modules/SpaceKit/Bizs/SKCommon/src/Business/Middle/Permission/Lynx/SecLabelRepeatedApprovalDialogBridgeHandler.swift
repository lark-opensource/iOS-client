//
//  SecLabelRepeatedApprovalDialogBridgeHandler.swift
//  SKCommon
//
//  Created by peilongfei on 2023/5/17.
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

class SecLabelRepeatedApprovalDialogBridgeHandler: NSObject, BridgeHandler {

    let methodName = "ccm.permission.repeatedApprovalDialog"
    let handler: BDXLynxBridgeHandler

    init(hostController: UIViewController) {
        handler = { [weak hostController] _, _, params, callback in
            guard let token = params?["token"] as? String,
                    let type = params?["type"] as? Int,
                    let originalSecLabelDic = params?["originalSecLabel"],
                    let targetSecLabelDic = params?["targetSecLabel"],
                    let secLabelApprovalDefDic = params?["secLabelApprovalDef"],
                    let secLabelApprovalListDic = params?["secLabelApprovalList"]
            else {
                DocsLogger.error("adjustSettingsCallback: no params")
                return
            }
            let originalSecLabel = SecretLevelLabel(json: JSON(originalSecLabelDic))
            let targetSecLabel = SecretLevelLabel(json: JSON(targetSecLabelDic))
            let secLabelApprovalDef = SecretLevelApprovalDef(json: JSON(secLabelApprovalDefDic))
            let secLabelApprovalList = SecretLevelApprovalList(json: JSON(secLabelApprovalListDic))
            let hostVC = hostController
            Self.shouldApprovalAlert(token: token, type: type, approvalList: secLabelApprovalList, selectedLevelLabel: targetSecLabel, topVC: hostVC, callback: callback)
            DocsLogger.info("handle ccm.permission.secLabelApproval")
        }
    }

    static func shouldApprovalAlert(token: String, type: Int, approvalList: SecretLevelApprovalList, selectedLevelLabel: SecretLevelLabel, topVC: UIViewController?, callback: @escaping (Int, [AnyHashable: Any]?) -> Void) {
        guard let topVC = topVC else {
            DocsLogger.error("topVC is nil", component: LogComponents.comment)
            return
        }

        if let myInstance = approvalList.myInstance, !myInstance.applySecLabelId.isEmpty {
            let dialog = SecretApprovalDialog.selfRepeatedApprovalDialog {
                callback(BDXBridgeStatusCode.succeeded.rawValue, ["actionID": "cancel"])
            } define: {
                callback(BDXBridgeStatusCode.succeeded.rawValue, ["actionID": "confirm"])
            }
            topVC.present(dialog, animated: true, completion: nil)
            return
        }

        let otherRepeatedApprovalCount = approvalList.instances(with: selectedLevelLabel.id).count
        if otherRepeatedApprovalCount > 0 {
            let dialog = SecretApprovalDialog.otherRepeatedApprovalDialog(num: otherRepeatedApprovalCount, name: selectedLevelLabel.name) {
                Self.showApprovalList(token: token, type: type, approvalList: approvalList, selectedLevelLabel: selectedLevelLabel, topVC: topVC)
            } cancel: {
                callback(BDXBridgeStatusCode.succeeded.rawValue, ["actionID": "cancel"])
            } define: {
                callback(BDXBridgeStatusCode.succeeded.rawValue, ["actionID": "confirm"])
            }
            topVC.present(dialog, animated: true, completion: nil)
            return
        }

        callback(BDXBridgeStatusCode.failed.rawValue, nil)
    }

    static func showApprovalList(token: String, type: Int, approvalList: SecretLevelApprovalList, selectedLevelLabel: SecretLevelLabel, topVC: UIViewController?) {
        guard let topVC = UIViewController.docs.topMost(of: topVC) else {
            DocsLogger.error("topVC is nil", component: LogComponents.comment)
            return
        }
        let viewModel = SecretApprovalListViewModel(label: selectedLevelLabel, instances: approvalList.instances(with: selectedLevelLabel.id),
                                                    wikiToken: nil, token: token,
                                                    type: type, permStatistic: nil, viewFrom: .resubmitView)
        let vc = SecretLevelApprovalListViewController(viewModel: viewModel, needCloseBarItem: true)
        let navVC = LkNavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = topVC.isMyWindowRegularSizeInPad ? .formSheet :.fullScreen
        Navigator.shared.present(navVC, from: topVC)
    }
}
