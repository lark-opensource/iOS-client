//
//  RealNameAuthService.swift
//  SKCommon
//
//  Created by Weston Wu on 2023/11/9.
//

import Foundation
import SKInfra
import UniverseDesignDialog
import UniverseDesignColor
import EENavigator
import SKResource
import SKFoundation

enum RealNameAuthService {

    private static var personalAuthURL: URL? {
        SettingConfig.larkAuthConfig?.realNameAuthURL
    }

    private static var tenantAuthURL: URL? {
        SettingConfig.larkAuthConfig?.tenantAuthURL
    }

    private static let fromValue = "public_doc_control"

    enum Scene: Int {
        /// 操作者是 owner && 管理员，引导进行租户认证或用户认证
        case requirePersonalAuthOrTenantAuth = 2501
        /// 操作者是 owner && 普通成员，引导进行用户认证
        case requirePersonalAuth = 2502
        /// 操作者非 owner，提醒用户让文档 owner 进行操作
        case requireOwnerAuth = 2503
    }

    static func showRealNameAuthDialog(scene: Scene, isFolder: Bool, fromVC: UIViewController) {
        switch scene {
        case .requirePersonalAuthOrTenantAuth:
            showPersonalOrTenantAuthDialog(fromVC: fromVC)
        case .requirePersonalAuth:
            showPersonalAuthDialog(fromVC: fromVC)
        case .requireOwnerAuth:
            showOwnerAuthDialog(isFolder: isFolder, fromVC: fromVC)
        }
        Tracker.reportDialogView(scene: scene)
    }

    private static func createStandardTextView() -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = UDColor.bgFloat
        textView.textColor = UDColor.textTitle
        textView.textAlignment = .center
        textView.isEditable = false
        textView.isUserInteractionEnabled = true
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.showsHorizontalScrollIndicator = false
        textView.showsVerticalScrollIndicator = false
        return textView
    }

    private static func showPersonalOrTenantAuthDialog(fromVC: UIViewController) {
        let config = UDDialogUIConfig(style: .vertical)
        let dialog = UDDialog(config: config)
        dialog.setTitle(text: BundleI18n.SKResource.LarkCCM_Docs_TNS_AnyoneAccess_Fail_Title)
        let personalAuthString = BundleI18n.SKResource.LarkCCM_Docs_TNS_AnyoneAccess_RealName_Button
        let contentString = BundleI18n.SKResource.LarkCCM_Docs_TNS_AnyoneAccess_RealNameAndOrg_Descrip(personalAuthString)
        let paragraphStyle = NSMutableParagraphStyle()
        let attributedString = NSMutableAttributedString(string: contentString, attributes: [
            .font: UIFont.systemFont(ofSize: 16),
            .paragraphStyle: paragraphStyle
        ])
        if let linkRange = contentString.range(of: personalAuthString),
           let linkURL = personalAuthURL {
            attributedString.addAttribute(.link, value: linkURL, range: NSRange(linkRange, in: contentString))
        } else {
            DocsLogger.error("failed to get linkRange or personal auth url when show dialog for tenant admin")
        }
        let textView = createStandardTextView()
        textView.attributedText = attributedString
        let urlHandler = TextViewURLHandler { [weak dialog, weak fromVC] url in
            guard let dialog, let fromVC else {
                spaceAssertionFailure("dialog and fromVC found nil")
                return
            }
            Tracker.reportDialogClick(scene: .requirePersonalAuthOrTenantAuth, event: .personalCertificationByLink)
            dialog.dismiss(animated: true) {
                if fromVC.navigationController != nil {
                    Navigator.shared.push(url, context: ["from": fromValue], from: fromVC)
                } else {
                    Navigator.shared.present(url, context: ["showTemporary": false, "from": fromValue], from: fromVC)
                }
            }
        }
        textView.delegate = urlHandler

        dialog.setContent(view: textView)
        dialog.addPrimaryButton(text: BundleI18n.SKResource.LarkCCM_Docs_TNS_AnyoneAccess_FeishuVerify_Button, dismissCompletion: { [weak fromVC] in
            guard let fromVC else { return }
            guard let tenantAuthURL else {
                DocsLogger.error("failed to get tenant auth URL when click dialog for admin")
                return
            }
            if fromVC.navigationController != nil {
                Navigator.shared.push(tenantAuthURL, context: ["from": fromValue], from: fromVC)
            } else {
                Navigator.shared.present(tenantAuthURL, context: ["showTemporary": false, "from": fromValue], from: fromVC)
            }
            Tracker.reportDialogClick(scene: .requirePersonalAuthOrTenantAuth, event: .tenantCertification)
            // 这里是为了让 dialog 强引用一下 urlHandler，使 urlHandler 的生命周期与 dialog 相同
            urlHandler.foo()
        })
        dialog.addSecondaryButton(text: BundleI18n.SKResource.LarkCCM_Docs_TNS_AnyoneAccess_NotNow_Button, dismissCompletion: {
            Tracker.reportDialogClick(scene: .requirePersonalAuthOrTenantAuth, event: .noCertification)
        })
        Navigator.shared.present(dialog, from: fromVC)
    }

    private static func showPersonalAuthDialog(fromVC: UIViewController) {
        let config = UDDialogUIConfig(style: .vertical)
        let dialog = UDDialog(config: config)
        dialog.setTitle(text: BundleI18n.SKResource.LarkCCM_Docs_TNS_AnyoneAccess_Fail_Title)
        dialog.setContent(text: BundleI18n.SKResource.LarkCCM_Docs_TNS_AnyoneAccess_Fail_RealNameRequired_Descrip)
        dialog.addPrimaryButton(text: BundleI18n.SKResource.LarkCCM_Docs_TNS_AnyoneAccess_RealName_Button, dismissCompletion: { [weak fromVC] in
            guard let fromVC else { return }
            guard let personalAuthURL else {
                DocsLogger.error("failed to get personal auth url when click personal auth dialog")
                return
            }
            if fromVC.navigationController != nil {
                Navigator.shared.push(personalAuthURL, context: ["from": fromValue], from: fromVC)
            } else {
                Navigator.shared.present(personalAuthURL, context: ["showTemporary": false, "from": fromValue], from: fromVC)
            }
            Tracker.reportDialogClick(scene: .requirePersonalAuth, event: .personalCertification)
        })
        dialog.addSecondaryButton(text: BundleI18n.SKResource.LarkCCM_Docs_TNS_AnyoneAccess_GotIt_Button, dismissCompletion: {
            Tracker.reportDialogClick(scene: .requirePersonalAuth, event: .noCertification)
        })
        Navigator.shared.present(dialog, from: fromVC)
    }

    private static func showOwnerAuthDialog(isFolder: Bool, fromVC: UIViewController) {
        let config = UDDialogUIConfig(style: .vertical)
        let dialog = UDDialog(config: config)
        dialog.setTitle(text: BundleI18n.SKResource.LarkCCM_Docs_TNS_AnyoneAccess_Fail_Title)
        if isFolder {
            dialog.setContent(text: BundleI18n.SKResource.LarkCCM_Docs_TNS_AnyoneAccess_FolderOwnder_Descrip)
        } else {
            dialog.setContent(text: BundleI18n.SKResource.LarkCCM_Docs_TNS_AnyoneAccess_DocOwner_Descrip)
        }
        dialog.addPrimaryButton(text: BundleI18n.SKResource.LarkCCM_Docs_TNS_AnyoneAccess_GotIt_Button, dismissCompletion: {
            Tracker.reportDialogClick(scene: .requireOwnerAuth, event: .noCertification)
        })
        Navigator.shared.present(dialog, from: fromVC)
    }
}

private class TextViewURLHandler: NSObject, UITextViewDelegate {

    let handler: (URL) -> Void

    init(handler: @escaping (URL) -> Void) {
        self.handler = handler
        super.init()
    }

    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        handler(url)
        return false
    }

    func foo() {}
}

private extension RealNameAuthService.Scene {
    var statisticValue: String {
        switch self {
        case .requirePersonalAuthOrTenantAuth:
            "admin"
        case .requirePersonalAuth:
            "tenant_member"
        case .requireOwnerAuth:
            "non_owner"
        }
    }
}

private extension RealNameAuthService {
    enum Tracker {
        
        static func reportDialogView(scene: Scene) {
            DocsTracker.newLog(enumEvent: .permissionInternetForbiddenView,
                               parameters: [
                                "trigger_type": scene.statisticValue
                               ])
        }

        enum ClickEvent: String {
            // 暂不认证
            case noCertification = "no_certification"
            case personalCertification = "certification_real_name"
            case tenantCertification = "certification_feishu"
            case personalCertificationByLink = "real_name_link"
        }

        static func reportDialogClick(scene: Scene, event: ClickEvent) {
            DocsTracker.newLog(enumEvent: .permissionInternetForbiddenClick,
                               parameters: [
                                "trigger_type": scene.statisticValue,
                                "click": event.rawValue,
                                "target": "none"
                               ])
        }

    }
}
