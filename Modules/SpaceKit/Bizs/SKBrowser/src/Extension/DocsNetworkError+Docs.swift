//
//  DocsNetworkError+Docs.swift
//  SKBrowser
//
//  Created by lijuyou on 2020/7/14.
//  


import Foundation
import SKCommon
import EENavigator
import SKUIKit
import SKFoundation
import SKResource
import UniverseDesignDialog

// From  DocsNetworkError+UI
extension DocsNetworkError {
   public static func showTips(for error: DocsNetworkError.Code, msg: String? = nil, from: UIViewController) {
        if error == .createLimited {
            showTipsForCreateLimited(msg ?? "", from: from)
        }
    }

    private static func showTipsForCreateLimited(_ msg: String, from: UIViewController) {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.Doc_List_CreateDocumentExceedLimit)
        dialog.setContent(text: msg)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel)
        dialog.addDestructiveButton(text: BundleI18n.SKResource.Doc_Facade_NotifyAdminUpgrade, dismissCheck: {  [weak dialog] in
            let isChecked = dialog?.isChecked ?? false
            CreateLimitedNotifyRequest.report(isChecked)
            if isChecked {
                CreateLimitedNotifyRequest.notifysuitebot()
            }
            return true
        })
        Navigator.shared.present(dialog, from: from)
    }
}
