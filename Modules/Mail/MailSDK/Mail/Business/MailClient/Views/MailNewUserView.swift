//
//  MailNewUserView.swift
//  MailSDK
//
//  Created by Fawaz on 4/24/20.
//

import Foundation
import LarkLocalizations
import UniverseDesignTheme
import UniverseDesignIcon
import LarkIllustrationResource
import UIKit

@objc
enum MailNewUserViewType: Int {
    case gmail = 0
    case exchange = 1
    case apiOnboard = 2 // LarkMailServer的搬家
}

class MailNewUserView: UIView, OAuthViewable {

    private let primaryButtonTappedBlock: (ImportViewButtonType) -> Void
    private let policyTappedBlock: (MailPolicyType) -> Void
    private let showDisclaimerView: Bool
    private let userType: MailNewUserViewType

    private lazy var disclaimerView: MailDisclaimerView = {
        return MailDisclaimerView(delegate: self)
    }()

    required init(primaryButtonTappedBlock: @escaping (ImportViewButtonType) -> Void,
                  policyTappedBlock: @escaping (MailPolicyType) -> Void,
                  showDisclaimerView: Bool,
                  userType: MailNewUserViewType) {
        self.showDisclaimerView = showDisclaimerView
        self.primaryButtonTappedBlock = primaryButtonTappedBlock
        self.policyTappedBlock = policyTappedBlock
        self.userType = userType
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        let imageView = UIImageView(image: LarkIllustrationResource.Resources.emailInitializationFunctionWelcomeAndLink)
        addSubview(imageView)
        if showDisclaimerView && UIScreen.main.bounds.size.width <= 375 {
            imageView.snp.makeConstraints { (make) in
                make.size.equalTo(CGSize(width: 100, height: 100))
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview()
            }
        } else {
            imageView.snp.makeConstraints { (make) in
                make.size.equalTo(CGSize(width: 180, height: 180))
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview().offset(30)
            }
        }
        let usageView2 = UsageTipView(frame: CGRect(x: 0, y: 0, width: 285, height: 0 ))
        if userType == .apiOnboard {
            usageView2.setTitle(BundleI18n.MailSDK.Mail_Migration_OpenTheMailToMoveDescPointTwoMobile)
        } else {
            usageView2.setTitle(BundleI18n.MailSDK.Mail_Onboard_OAuth_Mobile_Desc3)
        }
        addSubview(usageView2)
        usageView2.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalTo(285)
            make.height.equalTo(usageView2.getViewHeight())
            make.bottom.equalTo(imageView.snp.top).offset(-10)
        }
        usageView2.updateColor(color: UIColor.ud.textCaption)

        let usageView = UsageTipView(frame: CGRect(x: 0, y: 0, width: 285, height: 0 ))
        if userType == .apiOnboard {
            usageView.setTitle(BundleI18n.MailSDK.Mail_Migration_OpenTheMailToMoveDescPointOneMobile())

        } else {
            usageView.setTitle(BundleI18n.MailSDK.Mail_Onboard_OAuth_Mobile_Desc2())
        }
        addSubview(usageView)
        usageView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalTo(285)
            make.height.equalTo(usageView.getViewHeight())
            make.bottom.equalTo(usageView2.snp.top).offset(-3)
        }
        usageView.updateColor(color: UIColor.ud.textCaption)

        let contentLabel = UILabel()
        contentLabel.font = UIFont.systemFont(ofSize: 14)
        if userType == .apiOnboard {
            contentLabel.textColor = UIColor.ud.textTitle
        } else {
            contentLabel.textColor = UIColor.ud.textCaption
        }
        contentLabel.numberOfLines = 0
        contentLabel.textAlignment = .left
        if userType == .apiOnboard {
            let address = Store.settingData.getCachedCurrentSetting()?.emailAlias.defaultAddress.address
            let string = BundleI18n.MailSDK.Mail_Migration_OpenTheMailToMoveDescMobile(address ?? "")
            let attributedString = NSMutableAttributedString.init(string: string)
            if let address = address, let range = string.nsRange(of: address) {
                attributedString.setAttributes([NSAttributedString.Key.foregroundColor: UIColor.ud.primaryContentDefault], range: range)
            }
            contentLabel.attributedText = attributedString

        } else {
            contentLabel.text = BundleI18n.MailSDK.Mail_Onboard_OAuth_Mobile_Desc()
        }
        addSubview(contentLabel)
        contentLabel.snp.makeConstraints { (make) in
            make.width.equalTo(285)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(usageView.snp.top).offset(-10)
        }

        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .heavy)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .left
        if userType == .apiOnboard {
            titleLabel.text = BundleI18n.MailSDK.Mail_Migration_OpenTheMailToMoveMobile
            if let account = Store.settingData.getCachedCurrentAccount(), account.isShared {
                titleLabel.text = BundleI18n.MailSDK.Mail_Migration_EnablePublicMailboxMigrationMobile
            }
        } else {
            titleLabel.text = BundleI18n.MailSDK.Mail_Onboard_Welcome()
        }
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.width.equalTo(285)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(contentLabel.snp.top).offset(-10)
        }

        let btnView = UIView()
        addSubview(btnView)
        btnView.snp.makeConstraints { (make) in
            make.width.equalTo(216)
            make.height.equalTo(48)
            make.centerX.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).offset(10)
        }
        btnView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        btnView.clipsToBounds = true
        btnView.layer.cornerRadius = 8
        btnView.layer.borderWidth = 0.5
        btnView.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
        let btnImageView = UIImageView()
        btnImageView.frame = CGRect(x: 11, y: 11, width: 26, height: 26)
        btnView.addSubview(btnImageView)
        if userType == .gmail {
            btnImageView.image = UDIcon.googleColorful
        } else if userType == .exchange {
            btnImageView.image = Resources.exchange_icon
        } else {
            btnImageView.isHidden = true
        }
        btnImageView.contentMode = .scaleToFill
        let label = UILabel()
        label.backgroundColor = UIColor.ud.primaryContentDefault
        if userType == .gmail {
            label.frame = CGRect(x: 48, y: 0, width: 216 - 48, height: 48)
            label.text = BundleI18n.MailSDK.Mail_Onboard_OAuthButton
        } else if userType == .exchange {
            label.frame = CGRect(x: 48, y: 0, width: 216 - 48, height: 48)
            label.text = BundleI18n.MailSDK.Mail_Outlook_AssociateOutlookMailbox
        } else {
            label.frame = CGRect(x: 0, y: 0, width: 216, height: 48)
            label.text = BundleI18n.MailSDK.Mail_Migration_EnterFeishuMailboxMobile()
        }

        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        btnView.addSubview(label)
        label.textAlignment = .center
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        let singleTap = UITapGestureRecognizer.init(target: self, action: #selector(primaryButtonTapped))
        btnView.addGestureRecognizer(singleTap)

        if showDisclaimerView {
            addSubview(disclaimerView)
            disclaimerView.snp.makeConstraints { (maker) in
                maker.width.equalToSuperview()
                maker.top.equalTo(btnView.snp.bottom)
                maker.bottom.equalToSuperview()
                maker.left.equalToSuperview()
                maker.right.equalToSuperview()
            }
        }
    }
}

private extension MailNewUserView {
    @objc
    func primaryButtonTapped() {
        primaryButtonTappedBlock(ImportViewButtonType.googleOauthBtn)
    }
}

extension MailNewUserView: MailDisclaimerViewDelegate {
    func mailDisclaimerView(_ view: MailDisclaimerView, didTap policy: MailPolicyType) {
        policyTappedBlock(policy)
    }
}
