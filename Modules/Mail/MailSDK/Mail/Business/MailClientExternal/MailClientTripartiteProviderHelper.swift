//
//  MailClientTripartiteProviderHelper.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2022/2/18.
//

import Foundation
import UIKit
import UniverseDesignIcon
import RustPB

class MailClientTripartiteProviderHelper {
    static func makeDefaultAccount(type: MailTripartiteProvider, address: String? = nil, password: String? = nil, 
                                   protocolConfig: Email_Client_V1_ProtocolConfig.ProtocolEnum = .imap) -> Email_Client_V1_TripartiteAccount {
        var defaultAccount = Email_Client_V1_TripartiteAccount()
        if let address = address {
            defaultAccount.address = address
        }
        var pass = Email_Client_V1_LoginPass()
        pass.type = .password
        if let password = password {
            pass.authCode = password
        }
        defaultAccount.pass = pass
        defaultAccount.provider = type
        var receiverProtocolConfig = Email_Client_V1_ProtocolConfig()
        receiverProtocolConfig.protocol = protocolConfig
        receiverProtocolConfig.encryption = .ssl

        var senderProtocolConfig = Email_Client_V1_ProtocolConfig()
        senderProtocolConfig.protocol = .smtp
        senderProtocolConfig.encryption = .ssl

        // disable-lint: magic_number -- 邮件协议端口号
        switch type {

        case .office365, .outlook:
            receiverProtocolConfig.domain = "outlook.office365.com"
            receiverProtocolConfig.port = 993
            senderProtocolConfig.domain = "smtp.office365.com"
            senderProtocolConfig.port = 587
            senderProtocolConfig.encryption = .starttls

        case .office365Cn:
            receiverProtocolConfig.domain = "partner.outlook.cn"
            receiverProtocolConfig.port = 993
            senderProtocolConfig.domain = "smtp.partner.outlook.cn"
            senderProtocolConfig.port = 587
            senderProtocolConfig.encryption = .starttls

        case .gmail:
            receiverProtocolConfig.domain = "imap.gmail.com"
            receiverProtocolConfig.port = 993
            senderProtocolConfig.domain = "smtp.gmail.com"
            senderProtocolConfig.port = 465

        case .tencent:
            receiverProtocolConfig.domain = "imap.exmail.qq.com"
            receiverProtocolConfig.port = 993
            senderProtocolConfig.domain = "smtp.exmail.qq.com"
            senderProtocolConfig.port = 465

        case .netEase:
            receiverProtocolConfig.domain = "imaphz.qiye.163.com"
            receiverProtocolConfig.port = 993
            senderProtocolConfig.domain = "smtphz.qiye.163.com"
            senderProtocolConfig.port = 994

        case .ali:
            receiverProtocolConfig.domain = "imap.mxhichina.com"
            receiverProtocolConfig.port = 993
            senderProtocolConfig.domain = "smtp.mxhichina.com"
            senderProtocolConfig.port = 465

        case .zoho:
            receiverProtocolConfig.port = 993
            senderProtocolConfig.port = 465

        case .other, .coreMail, .exchangeOnPrem:
            receiverProtocolConfig.port = 993
            senderProtocolConfig.port = 465
        @unknown default:
            receiverProtocolConfig.port = -1
            senderProtocolConfig.port = -1
        }
        // enable-lint: magic_number

        defaultAccount.receiver = receiverProtocolConfig
        defaultAccount.sender = senderProtocolConfig
        guard let setting = ProviderManager.default.commonSettingProvider,
              let json = setting.originalSettingValue(configName: .mailClientURLKey),
              let data = json.data(using: .utf8),
              let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            MailLogger.error("mailClientURLKey config is nil")
            return defaultAccount
        }
        
        if let domainDic = jsonDict["zoho_server_domain"] as? [String: String], type == .zoho {
            receiverProtocolConfig.domain = domainDic["imap"] ?? ""
            senderProtocolConfig.domain = domainDic["smtp"] ?? ""
            defaultAccount.receiver = receiverProtocolConfig
            defaultAccount.sender = senderProtocolConfig
        }
        if protocolConfig != .exchange {
            defaultAccount.sender = senderProtocolConfig
        }
        return defaultAccount
    }

    // disable-lint: magic_number -- 邮件协议端口号
    static func defaultConfig() -> (Email_Client_V1_ProtocolConfig, Email_Client_V1_ProtocolConfig) {
        var receiverProtocolConfig = Email_Client_V1_ProtocolConfig()
        receiverProtocolConfig.protocol = .imap
        receiverProtocolConfig.encryption = .ssl
        receiverProtocolConfig.port = 993

        var senderProtocolConfig = Email_Client_V1_ProtocolConfig()
        senderProtocolConfig.protocol = .smtp
        senderProtocolConfig.encryption = .ssl
        senderProtocolConfig.port = 465
        return (receiverProtocolConfig, senderProtocolConfig)
    }
    // enable-lint: magic_number
}

extension MailTripartiteProvider {
    var bindType: String {
        switch self {
        case .gmail:
            return "bind_google"
        case .office365:
            return "bind_office_365"
        case .tencent:
            return "bind_tencent"
        case .ali:
            return "bind_ali"
        case .zoho:
            return "bind_zoho"
        case .netEase:
            return "bind_163"
        case .other:
            return "bind_others"
        @unknown default:
            mailAssertionFailure("mail bind type not handle: \(self.rawValue)")
            return "unknown"
        }
    }
    
    var pageType: String {
        switch self {
        case .office365:
            return "office365"
        case .tencent:
            return "tencent"
        case .ali:
            return "ali"
        case .zoho:
            return "zoho"
        case .netEase:
            return "netease"
        case .other:
            return "others"
        @unknown default:
            mailAssertionFailure("mail bind type not handle: \(self.rawValue)")
            return "unknown"
        }

    }
    func config() -> (String, UIImage) {
        switch self {
        case .office365:
            if FeatureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false) {
                return (BundleI18n.MailSDK.Mail_LinkYourBusinessEmailToLark_M365_Text, UDIcon.getIconByKey(.emailOffice365Colorful, size: CGSize(width: 70, height: 70)))
            } else {
                return (BundleI18n.MailSDK.Mail_Shared_AddEAS_Microsoft365_MenuItemName, UDIcon.getIconByKey(.emailOffice365Colorful, size: CGSize(width: 70, height: 70)))
            }
        case .office365Cn, .o365:
            return (BundleI18n.MailSDK.Mail_Shared_AddEAS_Microsoft365_MenuItemName, UDIcon.getIconByKey(.emailOffice365Colorful, size: CGSize(width: 70, height: 70)))
        case .outlook:
            return (BundleI18n.MailSDK.Mail_ThirdClient_Outlook, UDIcon.getIconByKey(.emailOutlookColorful, size: CGSize(width: 70, height: 70)))
        case .exchangeOnPrem, .exchange:
            return (BundleI18n.MailSDK.Mail_ThirdClient_Exchange, UDIcon.getIconByKey(.emailExchangeColorful, size: CGSize(width: 70, height: 70)))
        case .gmail:
            if FeatureManager.realTimeOpen(.newFreeBindMail, openInMailClient: false) {
                return (BundleI18n.MailSDK.Mail_LinkYourBusinessEmailToLark_Gmail_Text, UDIcon.getIconByKey(.emailGmailColorful, size: CGSize(width: 70, height: 70)))
            } else {
                return (BundleI18n.MailSDK.Mail_ThirdClient_Google, UDIcon.getIconByKey(.emailGmailColorful, size: CGSize(width: 70, height: 70)))
            }
        case .tencent:
            return (BundleI18n.MailSDK.Mail_ThirdClient_TecentExmail, UDIcon.getIconByKey(.emailTencentmailColorful, size: CGSize(width: 70, height: 70)))
        case .netEase, .netEasy:
            return (BundleI18n.MailSDK.Mail_ThirdClient_163Mail, UDIcon.getIconByKey(.emailNeteasemailColorful, size: CGSize(width: 70, height: 70)))
        case .ali:
            return (BundleI18n.MailSDK.Mail_ThirdClient_AliMail, UDIcon.getIconByKey(.emailAlibabamailColorful, size: CGSize(width: 70, height: 70)))
        case .zoho:
            return (BundleI18n.MailSDK.Mail_ThirdClient_ZohoMail, UDIcon.getIconByKey(.emailZohoColorful, size: CGSize(width: 70, height: 70)))
        case .coreMail:
            return (BundleI18n.MailSDK.Mail_ThirdClient_Coremail, UDIcon.getIconByKey(.emailCoremailColorful, size: CGSize(width: 70, height: 70)))
        case .other:
            return (BundleI18n.MailSDK.Mail_ThirdClient_Others, UDIcon.getIconByKey(.emailOthermailColorful, size: CGSize(width: 70, height: 70)))
        @unknown default:
            return (BundleI18n.MailSDK.Mail_ThirdClient_Others,
                    UDIcon.getIconByKey(.tabMailFilled, size: CGSize(width: 70, height: 70)).withRenderingMode(.alwaysTemplate))
        }
    }

    func needRenderIcon() -> Bool {
        switch self {
        case .office365, .office365Cn, .tencent, .netEase, .ali, .outlook, .exchange, .netEasy, .o365, .gmail, .coreMail, .zoho, .exchangeOnPrem:
            return false
        case .other:
            return true
        @unknown default:
            return false
        }
    }

    func isEASLogin() -> Bool {
        if (self == .office365 || self == .office365Cn || self == .outlook
            || self == .exchangeOnPrem || self == .exchange), FeatureManager.open(FeatureKey(fgKey: .eas, openInMailClient: true)) {
            return true
        }
        return false
    }

    func isTokenLogin() -> Bool {
        guard let setting = ProviderManager.default.commonSettingProvider,
              let json = setting.originalSettingValue(configName: .mailOAuthClientConfigKey), !json.isEmpty else {
            return false
        }
        if self == .office365 || self == .outlook {
            return true
        }
        if self == .office365Cn {
            return true
        }
        if self == .gmail, FeatureManager.open(FeatureKey(fgKey: .mailClientOAuthLoginGmail, openInMailClient: true)) {
            return true
        }
        return false
    }

    func needShowPassLoginExpried() -> Bool {
        guard let setting = ProviderManager.default.commonSettingProvider,
              let json = setting.originalSettingValue(configName: .mailOAuthClientConfigKey), !json.isEmpty else {
            return false
        }
        if self == .office365 || self == .outlook {
            return true
        }
        if self == .office365Cn {
            return true
        }
        return false
    }

    func loginWithAdvanceSetting(protocolConfig: Email_Client_V1_ProtocolConfig.ProtocolEnum = .imap) -> Bool {
        if FeatureManager.open(.eas, openInMailClient: true) && protocolConfig == .exchange {
            return self == .other || self == .coreMail
        } else {
            return self == .other || self == .coreMail || self == .exchangeOnPrem
        }
    }

    func apmValue() -> Int {
        switch self {
        case .office365Cn:
            return 1
        case .tencent:
            return 2
        case .netEase, .netEasy:
            return 3
        case .ali:
            return 4
        case .office365, .o365:
            return 5
        case .exchange, .other, .gmail, .coreMail, .zoho, .outlook, .exchangeOnPrem:
            return 0
        @unknown default:
            return 0
        }
    }
}

extension Email_Client_V1_ProtocolConfig.ProtocolEnum {
    func title() -> String {
        if self == .exchange {
            return BundleI18n.MailSDK.Mail_Shared_AddEAS_EAS_DropdownList
        } else if self == .imap {
            return BundleI18n.MailSDK.Mail_Shared_AddEAS_IMAP_DropdownList
        } else {
            return ""
        }
    }
}

extension RustPB.Email_Client_V1_LoginPass.TypeEnum {
    func apmValue() -> Int {
        switch self {
        case .password:
            return 1
        case .token:
            return 2
        @unknown default:
            return 1
        }
    }
}

extension Email_Client_V1_TripartiteAccount {
    func apmProtocolValue() -> Int {
        if self.receiver.protocol == .imap, self.sender.protocol == .smtp {
            return 1
        } else if self.receiver.protocol == .pop3, self.sender.protocol == .smtp {
            return 2
        } else if self.receiver.protocol == .exchange, self.sender.protocol == .exchange {
            return 3
        }
        return 1
    }
}

extension Email_Client_V1_ProtocolConfig {

    func apmEncryptionValue() -> Int {
        switch self.encryption {
        case .none:
            return 0
        case .ssl:
            return 1
        case .starttls:
            return 2
        @unknown default:
            return 0
        }
    }
}
