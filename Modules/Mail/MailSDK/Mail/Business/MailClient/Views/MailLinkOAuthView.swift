//
//  MailLinkOAuthView.swift
//  MailSDK
//
//  Created by Fawaz on 4/24/20.
//

import Foundation
import LarkButton
import UniverseDesignEmpty

class MailLinkOAuthView: UIView, OAuthViewable {

    private let primaryButtonTappedBlock: (ImportViewButtonType) -> Void

    required init(primaryButtonTappedBlock: @escaping (ImportViewButtonType) -> Void,
                  policyTappedBlock: @escaping (MailPolicyType) -> Void,
                  showDisclaimerView: Bool,
                  userType: MailNewUserViewType) {
        self.primaryButtonTappedBlock = primaryButtonTappedBlock
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        let container = UIView()
        container.backgroundColor = .clear
        addSubview(container)
        
        let button = TypeButton(style: .normalA)
        let imageView = UIImageView(image: UDEmptyType.error.defaultImage())
        container.addSubview(imageView)

        let textLabel = UILabel()
        textLabel.numberOfLines = 0

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.alignment = .center
        var address = ""
        if let setting = Store.settingData.getCachedCurrentSetting() {
            address = setting.emailAlias.defaultAddress.address
        }
        let attributedString = NSAttributedString(string: BundleI18n.MailSDK.Mail_LinkAccount_YourAccountHasExpired_Desc(address),
                                                                   attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                                              .foregroundColor: UIColor.ud.textCaption,
                                                                              .paragraphStyle: paragraphStyle])

        container.addSubview(textLabel)
        textLabel.attributedText = attributedString
        button.setTitle(BundleI18n.MailSDK.Mail_LinkAccount_YourAccountHasExpired_Relink_Button, for: .normal)
        button.sizeToFit()
        button.addTarget(self, action: #selector(primaryButtonTapped), for: .touchUpInside)
        container.addSubview(button)
        
        let delinkBtn = TypeButton(style: .normalC)
        delinkBtn.setTitleColor(.ud.textTitle, for: .normal)
        delinkBtn.setTitle(BundleI18n.MailSDK.Mail_LinkAccount_YourAccountHasExpired_Unlink_Button, for: .normal)
        delinkBtn.sizeToFit()
        delinkBtn.addTarget(self, action: #selector(secondartButtonTapped), for: .touchUpInside)
        container.addSubview(delinkBtn)
        
        container.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(302)
        }

        imageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(100)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
        }

        textLabel.snp.makeConstraints { (make) in
            make.width.equalTo(302)
            make.centerX.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).offset(12)
        }

        button.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.height.equalTo(36)
            make.top.equalTo(textLabel.snp.bottom).offset(16)
        }
       
        delinkBtn.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.height.equalTo(36)
            make.top.equalTo(button.snp.bottom).offset(16)
            make.bottom.equalToSuperview()
        }
    }
}

private extension MailLinkOAuthView {
    @objc
    func primaryButtonTapped() {
        primaryButtonTappedBlock(ImportViewButtonType.googleOauthBtn)
    }
    @objc
    func secondartButtonTapped() {
        primaryButtonTappedBlock(ImportViewButtonType.oauthDelinkBtn)
    }

}
