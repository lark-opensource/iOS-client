//
//  MailPolicyType.swift
//  MailSDK
//
//  Created by Fawaz on 4/24/20.
//

import Foundation
import RustPB

enum MailPolicyType: CaseIterable {
    case privacy
    case termsOfUse
}

extension MailPolicyType {
    var string: String {
        switch self {
        case .privacy: return BundleI18n.MailSDK.Mail_Onboard_PrivacyPolicy
        case .termsOfUse: return BundleI18n.MailSDK.Mail_Onboard_UserTerm
        }
    }

    var url: URL? {
        switch self {
        case .privacy: return MailModelManager.shared.getAppConfigUrl(by: "help-private-policy")
        case .termsOfUse: return MailModelManager.shared.getAppConfigUrl(by: "help-user-agreement")
        }
    }
}
