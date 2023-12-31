//
//  OpenAPIAuthAgreementTableViewCell.swift
//  LarkAccount
//
//  Created by YuankaiZhu on 2023/10/31.
//

import UIKit
import UniverseDesignFont
import LarkLocalizations

class OpenAPIAuthAgreementTableViewCell: UITableViewCell {

    private lazy var agreementPlainString: String = {
        return I18N.Lark_Passport_ThirdPartyAppAuthorization_AuthRequestPage_TermsAndPolicyCheckbox_Text(I18N.Lark_Passport_ThirdPartyAppAuthorization_AuthRequestPage_TermsAndPolicyCheckbox_UsePolicy, I18N.Lark_Passport_ThirdPartyAppAuthorization_AuthRequestPage_TermsAndPolicyCheckbox_PrivacyPolicy)
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configCell(authInfo: OpenAPIAuthGetAuthInfo, vc: OpenAPIAuthInfoViewController) {
        if let alertAgreementLinks = getAgreementLinks(authInfo: authInfo) {
            let agreementLabel: AgreementView = AgreementView(
                needCheckBox: false,
                plainString: agreementPlainString,
                links: alertAgreementLinks,
                checkAction: { (_) in
                }) { [weak self](url, _, _) in
                    guard self != nil else {return}
                    vc.clickLink(url: url)
            }
            agreementLabel.updateContent(plainString: agreementPlainString, links: alertAgreementLinks, color: UIColor.ud.textTitle)

            contentView.addSubview(agreementLabel)
            agreementLabel.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(14)
                make.left.right.equalToSuperview().inset(16)
                make.height.equalTo(60)
            }
        }
    }

    private func getAgreementLinks(authInfo: OpenAPIAuthGetAuthInfo) -> [(String, URL)]? {
        let languageMapping: [LarkLocalizations.Lang : () -> I18nAgreementInfo?] = [
            .zh_CN: { authInfo.i18nAgreement?.zhCN },
            .ja_JP: { authInfo.i18nAgreement?.jaJP },
            .en_US: { authInfo.i18nAgreement?.enUS }
        ]

        if let agreementInfo = languageMapping[LanguageManager.currentLanguage]?() ?? authInfo.i18nAgreement?.enUS,
           let clauseUrl = URL(string: agreementInfo.clauseUrl),
           let privacyPolicyUrl = URL(string: agreementInfo.privacyPolicyUrl) {
            return [
                (I18N.Lark_Passport_ThirdPartyAppAuthorization_AuthRequestPage_TermsAndPolicyCheckbox_UsePolicy, clauseUrl),
                (I18N.Lark_Passport_ThirdPartyAppAuthorization_AuthRequestPage_TermsAndPolicyCheckbox_PrivacyPolicy, privacyPolicyUrl)
            ]
        }
        return nil
    }

}
