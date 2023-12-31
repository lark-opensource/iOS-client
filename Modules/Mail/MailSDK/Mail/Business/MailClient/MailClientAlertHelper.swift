//
//  MailClientAlertHelper.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/11/15.
//

import Foundation
import LarkAlertController
import EENavigator
import RxSwift
import Reachability
import UIKit

class MailClientAlertHelper {
    var showingAlert: LarkAlertController?
    var showingAlertOnDismiss: (() -> Void)?

    let navigator: Navigatable
    let oAuthoDisposeBag = DisposeBag()

    init(navigator: Navigatable) {
        self.navigator = navigator
    }

    func showCheckVpnAlertIfNeeded(fromVC: UIViewController) {
        let alert = LarkAlertController()
        alert.setContent(text: BundleI18n.MailSDK.Mail_Client_GmailConnectInvalid, alignment: .center)
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Alert_OK)
        navigator.present(alert, from: fromVC)
    }

    func showUnbindConfirmAlert(keepUsing: @escaping () -> Void, unbindEmail: @escaping () -> Void, fromVC: UIViewController) {
        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_Setting_UnbindConfirmTitle)
        alert.setContent(text: BundleI18n.MailSDK.Mail_Setting_UnbindConfirmBody, alignment: .center)
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Client_MailCloseCancel, dismissCompletion: keepUsing)
        alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_Setting_UnbindConfirmAction, dismissCompletion: unbindEmail)
        navigator.present(alert, from: fromVC)
    }

    func showDeleteConfirmAlert(keepUsing: @escaping () -> Void, deleteEmail: @escaping () -> Void, fromVC: UIViewController) {
        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_UnlinkThisAccount)
        alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_UnlinkThisAccountDesc, alignment: .center)
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Client_MailCloseCancel, dismissCompletion: keepUsing)
        alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_ThirdClient_Unlink, dismissCompletion: deleteEmail)
        navigator.present(alert, from: fromVC)
    }

    func showRevokeMailClientConfirmAlert(confirmHandler: (() -> Void)? = nil, fromVC: UIViewController) {
        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_PermissionRevoked)
        alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_PermissionRevokedDesc, alignment: .center)
        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_NewAccountOK, dismissCompletion: confirmHandler)
        navigator.present(alert, from: fromVC)
    }

    func showRevokeLMSConfirmAlert(confirmHandler: (() -> Void)? = nil, fromVC: UIViewController) {
        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_PermissionRevoked)
        alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_FeishuMailPermissionRevoked(), alignment: .center)
        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_NewAccountOK, dismissCompletion: confirmHandler)
        navigator.present(alert, from: fromVC)
    }

    func showRevokeGCConfirmAlert(confirmHandler: (() -> Void)? = nil, fromVC: UIViewController) {
        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_PermissionRevoked)
        alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_GooglePermissionRevoked, alignment: .center)
        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_NewAccountOK, dismissCompletion: confirmHandler)
        navigator.present(alert, from: fromVC)
    }

    func showLMSAddConfirmAlert(onboardEmail: String, confirmHandler: (() -> Void)? = nil, fromVC: UIViewController) {
        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_NewEmailAccountAdded)
        alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_NewEmailAccountAddedDesc(onboardEmail), alignment: .center)
        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_NewAccountOK, dismissCompletion: confirmHandler)
        navigator.present(alert, from: fromVC)
    }

    func showGCAddConfirmAlert(confirmHandler: (() -> Void)? = nil, fromVC: UIViewController) {
        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_NewEmailAccountLinked)
        alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_NewEmailAccountLinkedDesc, alignment: .center)
        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_NewAccountOK, dismissCompletion: confirmHandler)
        navigator.present(alert, from: fromVC)
    }

    func showApiMigrationAlert(onboardEmail: String, confirmHandler: (() -> Void)? = nil, fromVC: UIViewController) {
        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_EmailMigrationNotice)
        alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_EmailMigrationNoticeDesc(onboardEmail), alignment: .center)
        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_NewAccountOK, dismissCompletion: confirmHandler)
        navigator.present(alert, from: fromVC)
    }

    func showSharedAccountAlert(changes: [MailSharedAccountChange],
                                in controller: UIViewController,
                                onDismiss: (() -> Void)? = nil) -> LarkAlertController? {
        guard let change = changes.last else { return nil }

        /// dismiss showing alert
        //showingAlert?.dismiss(animated: true, completion: showingAlertOnDismiss)

        /// prepare new alert
        let accountId = change.account.mailAccountID
        let name = change.account.accountName
        let address = change.account.accountAddress
        let isBind = change.isBind

        let alert = LarkAlertController()

        alert.setTitle(text: BundleI18n.MailSDK.Mail_SharedEmail_SharedEmailNotificationCardTitle)
        var content = ""
        if isBind {
            content = BundleI18n.MailSDK.Mail_SharedEmail_SharedEmailNotificationCardDesc(name, address)
        } else {
            content = BundleI18n.MailSDK.Mail_SharedEmail_PermissionRecycledDesc(name, address)
        }
        alert.setContent(text: content,
                         color: UIColor.ud.textTitle,
                         font: UIFont.systemFont(ofSize: 16),
                         alignment: .left,
                         lineSpacing: 4,
                         numberOfLines: 0)
        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Alert_Confirm, dismissCompletion: {
                            onDismiss?()
                        })
        navigator.present(alert, from: controller)
        showingAlert = alert
        showingAlertOnDismiss = onDismiss

        NotificationCenter.default.post(name: Notification.Name.Mail.MAIL_DID_SHOW_SHARED_ACCOUNT_ALERT, object: nil)

        return alert
    }
    
    func showImapCannotLoginAlert(from: NavigatorFrom, pageType: String) {
        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_LinkAccount_AdvancedSetting_UnableToLogIn_Title)
        let contentView = MailStepAlertContentView(dataSource: imapLoginAlertDataSource(pageType: pageType))
        contentView.pagetType = pageType
        alert.setContent(view: contentView)
        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Client_GotItButton)
        navigator.present(alert, from: from)
    }
    
    private func imapLoginAlertDataSource(pageType: String) -> MailStepAlertContent {
        let steps: [MailStepAlertContent.AlertStep] = [(content: BundleI18n.MailSDK.Mail_LinkAccount_Instructions_Step1_Text, actionText: nil, action: nil),
                                                       (content: BundleI18n.MailSDK.Mail_LinkAccount_Instructions_Step2_Text,
                                                        actionText: BundleI18n.MailSDK.Mail_LinkAccount_Instructions_Details_Button,
                                                        action: {
            MailTracker.log(event: "email_other_mail_binding_click", params: ["click": "more_info_about_imap", "page_type": pageType])
            if let urlString = ProviderManager.default.commonSettingProvider?.stringValue(key: "open-imap")?.localLink,
               let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }),
                                                       (content: BundleI18n.MailSDK.Mail_LinkAccount_Instructions_Step3_Text,
                                                        actionText: BundleI18n.MailSDK.Mail_LinkAccount_Instructions_Details_Button,
                                                        action: {
            MailTracker.log(event: "email_other_mail_binding_click", params: ["click": "more_info_about_security", "page_type": pageType])
            if let urlString = ProviderManager.default.commonSettingProvider?.stringValue(key: "login-safety")?.localLink,
               let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        })]
        return MailStepAlertContent(title: BundleI18n.MailSDK.Mail_LinkAccount_AdvancedSetting_UnableToLogIn_Desc, steps: steps)
    }
}

extension MailClientAlertHelper {
    func openGoogleOauthPage(url: URL, fromVC: UIViewController?) {
        // 貌似用324版本开始，IM内置的浏览器跳Google授权页，用户第一次绑定，必然400，还在查这个问题，所以现在先用临时方案，跳外部浏览器
        UIApplication.shared.open(url)
    }
}
