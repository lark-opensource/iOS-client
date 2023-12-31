//
//  LarkMailService+MailClient.swift
//  LarkMail
//
//  Created by tefeng liu on 2019/11/18.
//

import Foundation
import RustPB
import MailSDK

// MARK: Mail Client
extension LarkMailService {
    /// call this when the tab should show auth page or quit alert. something like that
    @objc
    func handleAuthStatusChange(noti: Notification) {
        if let setting: Email_Client_V1_Setting = noti.userInfo?[Notification.Name.Mail.MAIL_SETTING_DATA_KEY] as? Email_Client_V1_Setting {
            reLaunchMail() // 更新未读数
        }
    }
}
