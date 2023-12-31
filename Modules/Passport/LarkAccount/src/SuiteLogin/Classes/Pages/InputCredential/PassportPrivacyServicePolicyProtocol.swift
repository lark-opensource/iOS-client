//
//  PassportPrivacyServicePolicyProtocol.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/8/20.
//

import Foundation
import LarkLocalizations
import LarkAlertController

protocol PassportPrivacyServicePolicyProtocol {
    var alertAgreePolicyTip: NSAttributedString { get }

    var currentPolicyPresentVC: UIViewController { get }

    func showPolicyAlert(delegate: UITextViewDelegate, completion:@escaping ((Bool) -> Void))
    func policyTip(isRegisterType: Bool) -> NSAttributedString
}

extension PassportPrivacyServicePolicyProtocol {

    func policyTip(isRegisterType: Bool) -> NSAttributedString {
        let font: UIFont = UIFont.systemFont(ofSize: 14.0)
        let res: String
        if isRegisterType {
            res = I18N.Lark_Login_V3_registerNextStepPolicyTip(I18N.Lark_Login_V3_TermService, I18N.Lark_Login_V3_PrivacyPolicy)
        } else {
            res = I18N.Lark_Login_V3_registerNextStepPolicyTip(I18N.Lark_Login_V3_TermService, I18N.Lark_Login_V3_PrivacyPolicy)
        }
        let attributedString = NSMutableAttributedString.tip(str: res, color: UIColor.ud.textPlaceholder, font: font, aligment: .left)
        let termAttributed: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.primaryContentDefault,
            .link: Link.termURL
        ]
        let privacyAttributed: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.primaryContentDefault,
            .link: Link.privacyURL
        ]
        do {
            let rng = (res as NSString).range(of: I18N.Lark_Login_V3_TermService)
            if rng.location != NSNotFound {
                attributedString.addAttributes(termAttributed, range: rng)
            }
        }
        do {
            let rng = (res as NSString).range(of: I18N.Lark_Login_V3_PrivacyPolicy)
            if rng.location != NSNotFound {
                attributedString.addAttributes(privacyAttributed, range: rng)
            }
        }
        return attributedString
    }

    var alertAgreePolicyTip: NSAttributedString {
        let font: UIFont = UIFont.systemFont(ofSize: 16.0)
        let res = I18N.Lark_Login_V3_AgreePolicyTip(I18N.Lark_Login_V3_TermService, I18N.Lark_Login_V3_PrivacyPolicy)
        let attributedString = NSMutableAttributedString.tip(
            str: res,
            color: UIColor.ud.textTitle,
            font: font,
            aligment: .left
        )
        let termAttributed: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.primaryContentDefault,
            .link: Link.alertTermURL
        ]
        let privacyAttributed: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.primaryContentDefault,
            .link: Link.alertPrivacyURL
        ]
        do {
            let rng = (res as NSString).range(of: I18N.Lark_Login_V3_TermService)
            if rng.location != NSNotFound {
                attributedString.addAttributes(termAttributed, range: rng)
            }
        }
        do {
            let rng = (res as NSString).range(of: I18N.Lark_Login_V3_PrivacyPolicy)
            if rng.location != NSNotFound {
                attributedString.addAttributes(privacyAttributed, range: rng)
            }
        }
        return attributedString
    }

    func showPolicyAlert(delegate: UITextViewDelegate, completion:@escaping ((Bool) -> Void)) {
        let controller = LarkAlertController()
        controller.setTitle(text: I18N.Lark_Login_V3_AgreePolicyTitle)
        let label = LinkClickableLabel.default(with: delegate)
        label.attributedText = self.alertAgreePolicyTip
        label.textAlignment = .center
        controller.setFixedWidthContent(view: label)
        controller.addSecondaryButton(
            text: I18N.Lark_Login_V3_PolicyAlertCancel,
            dismissCompletion: {
                completion(false)
            })
        controller.addPrimaryButton(
            text: I18N.Lark_Login_V3_PolicyAlertAgree,
            dismissCompletion: {
                completion(true)
            })
        self.currentPolicyPresentVC.present(controller, animated: true, completion: nil)
    }
}
