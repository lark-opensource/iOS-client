//
//  MailMessageItem+Extension.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2021/4/15.
//

import Foundation
import RustPB

extension MailMessageItem {
    /// 当前用户是否为发件人
    var isFromMe: Bool {
        if let addresses = Store.settingData.getCachedCurrentSetting()?.emailAlias.allAddresses {
            if addresses.first(where: { $0.larkEntityIDString == message.from.larkEntityIDString }) != nil {
                return true
            }
            if addresses.first(where: { $0.address == message.from.address }) != nil {
                return true
            }
        }
        return false
    }

    var showSafeTipsBanner: Bool {
        let security = message.security
        let isRisky = security.isSuspect || security.isPhishing || security.isSpoof
        let shouldShowSafeTips = security.reportType != .closed && security.reportType != .ham
        return FeatureManager.open(.riskBanner) && security.needRiskTips ? shouldShowSafeTips : isRisky && shouldShowSafeTips
    }
    
    var showSafeTipsNewBanner: Bool {
        return FeatureManager.open(.riskBanner) && message.security.needRiskTips
    }

    func auditMailInfo(ownerID: String?, isEML: Bool) -> AuditMailInfo {
        return AuditMailInfo(smtpMessageID: message.smtpMessageID, subject: message.subject, sender: message.from.address, ownerID: ownerID, isEML: isEML)
    }
    
    /// 当前用户是否为发件人，或是否由用户通过公共邮箱管理员身份发送，且不是伪造邮件
    func isSendByMe(myAddresses: [Email_Client_V1_Address], myUserID: String) -> Bool {
        if myAddresses.isEmpty || myUserID.isEmpty {
            return false
        }
        if message.security.isSpoof || !message.security.isFromAuthorized {
            return false
        }
        if myAddresses.first(where: { $0.larkEntityIDString == message.from.larkEntityIDString }) != nil {
            return true
        }
        if myAddresses.first(where: { $0.address == message.from.address }) != nil {
            return true
        }
        if (message.from.larkEntityType == .user || message.from.larkEntityType == .group) && (message.from.larkEntityIDString == myUserID) {
            return true
        }
        return false
    }
}

extension Email_Client_V1_Address {
    /// 发信地址是否属于当前账号，对齐 PC 逻辑
    func isMyAddress(myAccount: MailAccount?) -> Bool {
        guard let myAccount else { return false }
        if larkEntityType == .group {
            return false
        } else if myAccount.mailAccountID == larkEntityIDString || myAccount.accountAddress == address {
            return true
        } else {
            return myAccount.mailSetting.emailAlias.allAddresses.contains(where: { $0.address == address })
        }
    }
}

extension Email_Client_V1_SpamBannerType: Comparable {
    /// 优先级 userReport  > userRule  > userBlock > antiSpam
    public static func < (lhs: Email_Client_V1_SpamBannerType, rhs: Email_Client_V1_SpamBannerType) -> Bool {
        switch (lhs, rhs) {
        case (.userReport, _): return false
        case (_, .userReport): return true
        case (.userRule, _): return false
        case (_, .userRule): return true
        case (.userBlock, _): return false
        case (_, .userBlock): return true
        case (.antiSpam, _): return false
        case (_, .antiSpam): return true
        @unknown default: return false
        }
    }
}
