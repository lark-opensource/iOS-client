//
//  MailHomeController+OAuth.swift
//  MailSDK
//
//  Created by vvlong on 2021/6/22.
//

import Foundation
import EENavigator
import RxSwift
import LarkAlertController
import RustPB

extension MailHomeController: MailAuthStatusDelegate {

    // MARK: Internal Method
    func createOauthPageIfNeeded() {
        if oauthPlaceholderPage == nil {
            oauthPlaceholderPage = MailClientImportViewController(userContext: userContext)
            oauthPlaceholderPage?.displayDelegate = displayDelegate
            oauthPlaceholderPage?.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
    }

    func mailCurrentAccountChange(_ notification: Notification) {
        updateOauthStatus(viewType: oauthPageViewType)
    }

    func mailHideApiOnboardingPage(_ notification: Notification) {
        self.hideOauthPlaceholderPage()
    }

    // 认证状态变更，同时胶水层也监听此变化更新Tab上未读数
    func handleAuthStatusChange(noti: Notification) {
        MailLogger.debug("[mailTab] handleAuthStatusChange 刷新Auth Page 222")
        if let setting: Email_Client_V1_Setting = noti.userInfo?[Notification.Name.Mail.MAIL_SETTING_DATA_KEY] as? Email_Client_V1_Setting {
            self.refreshAuthPageIfNeeded(setting)
        }
    }
}
