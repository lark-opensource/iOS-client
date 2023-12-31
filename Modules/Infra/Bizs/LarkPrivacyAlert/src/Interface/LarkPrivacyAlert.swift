//
//  LarkPrivacyAlert.swift
//  LarkPrivacyAlert
//
//  Created by quyiming on 2020/4/28.
//

import Foundation
import LarkAppConfig
import LarkLocalizations

// swiftlint:disable missing_docs

public protocol PrivacyAlertConfigProtocol {

    // MARK: Privacy Alert

    /// need privacy alert
    /// - optional
    /// - default value: false
    var needPrivacyAlert: Bool { get }

    /// privacy url
    /// - optional
    /// - default value: ""
    var privacyURL: String { get }

    /// privacy url
    /// - optional
    /// - default value: ""
    var serviceTermURL: String { get }

    /// privacy link text
    /// - optional
    /// - default value: ""
    var privacyLinkText: String { get }

    /// service term link text
    /// - optional
    /// - default value: Lark_Guide_V3_PrivacyPolicy
    var serviceTermLinkText: String { get }

    /// privacy notice alert title
    /// - optional
    /// - default value: Lark_Guide_V3_serviceterms
    var privacyNoticeTitleText: String { get }

    /// privacy notice content
    /// - optional
    /// - default value: Lark_Login_V3_Lark_PrivacyNotice
    var privacyNoticeText: String { get }

    /// privacy agree button text
    /// - optional
    /// - default value:Lark_Login_V3_Lark_PrivacyButtonagree
    var privacyAgreeButtonText: String { get }

    /// privacy disagree button text
    /// - optional
    /// - default value: Lark_Login_V3_Lark_PrivacyButtondisagree
    var privacyDisagreeButtonText: String { get }

    /// pricacy disagree toast text
    /// - optional
    /// - default value: Lark_Login_AgreeToUse
    var privacyNoticeDisagreeToastText: String { get }

    /// service term privacy policy text
    /// - optional
    /// - default value: Lark_Login_ServiceTermPrivacyPolicy
    func serviceTermPrivacyPolicyText(serviceTerm: String, privacy: String) -> String

}

// MARK: Privacy Alert

typealias I18N = BundleI18n.LarkPrivacyAlert

public extension PrivacyAlertConfigProtocol {

    var needPrivacyAlert: Bool { false }

    var privacyURL: String { PrivacyConfig.privacyURL }

    var serviceTermURL: String { PrivacyConfig.termsURL }

    var privacyLinkText: String { I18N.Lark_Guide_V3_PrivacyPolicy }

    var serviceTermLinkText: String { I18N.Lark_Guide_V3_serviceterms }

    var privacyNoticeTitleText: String { I18N.Lark_Login_V3_Lark_PrivacyNoticeTitle }

    var privacyNoticeText: String { I18N.Lark_PrivacyPolicy_WhatsFeishu_PopupText() }

    var privacyAgreeButtonText: String { I18N.Lark_Login_V3_Lark_PrivacyButtonagree }

    var privacyDisagreeButtonText: String { I18N.Lark_Login_V3_Lark_PrivacyButtondisagree }

    var privacyNoticeDisagreeToastText: String { I18N.Lark_Login_AgreeToUse() }

    func serviceTermPrivacyPolicyText(serviceTerm: String, privacy: String) -> String {
        I18N.Lark_Login_ServiceTermPrivacyPolicy(serviceTerm, privacy)
    }
}

// swiftlint:enable missing_docs
