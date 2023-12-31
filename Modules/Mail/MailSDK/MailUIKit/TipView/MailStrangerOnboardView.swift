//
//  MailStrangerOnboardView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/8/23.
//

import Foundation
import UIKit
import SnapKit
import FigmaKit
import UniverseDesignButton
import UniverseDesignIcon
import RxSwift
import LarkGuideUI

class MailStrangerOnboardView: GuideCustomView {
    private let backgroundView = UIView()
    private let managePreview = UIImageView()
    private let allowIcon = UIImageView()
    private let rejectIcon = UIImageView()
    private let allowTitle = UILabel()
    private let rejectTitle = UILabel()
    private let allowDetail = UILabel()
    private let rejectDetail = UILabel()

    private let disposeBag = DisposeBag()
    private lazy var closeButton: UDButton = {
        let themeColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.primaryOnPrimaryFill, backgroundColor: UIColor.ud.primaryOnPrimaryFill, textColor: UIColor.ud.primaryContentDefault)
        var config = UDButtonUIConifg(normalColor: themeColor)
        let btnType: UDButtonUIConifg.CustomButtonType = (CGSize(width: 0, height: 48), 4, UIFont.systemFont(ofSize: 17, weight: .medium), .zero)
        var btnConfig = UDButtonUIConifg.textBlue
        config.type = .custom(type: btnType)
        let closeButton = UDButton(btnConfig)
        closeButton.layer.cornerRadius = 6
        closeButton.layer.masksToBounds = true
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        closeButton.titleLabel?.textColor = UIColor.ud.primaryContentDefault
        closeButton.setTitle(BundleI18n.MailSDK.Mail_StrangerInbox_OnboardingMobile_GotIt_Button, for: .normal)
        closeButton.config = config
        closeButton.rx.tap.subscribe(onNext: { [weak self] in
            guard let `self` = self else { return }
            self.closeHandler?()
        }).disposed(by: disposeBag)
        return closeButton
    }()
    var closeHandler: (() -> Void)? = nil

    @objc
    func dismiss() {
        closeGuideCustomView(view: self)
        closeHandler?()
    }

    override init(delegate: GuideCustomViewDelegate) {
        super.init(delegate: delegate)
        setupViews()
    }

//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupViews()
//    }

    func setupViews() {
        backgroundColor = UIColor.ud.bgMask.withAlphaComponent(0.4)

        backgroundView.backgroundColor = UIColor.ud.bgPricolor
        backgroundView.layer.ud.setShadow(type: .s4DownPri)
        backgroundView.layer.cornerRadius = 8
        backgroundView.layer.masksToBounds = true
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.width.equalTo(300)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        managePreview.image = Resources.stranger_onboard
        managePreview.backgroundColor = .darkGray
        managePreview.contentMode = .scaleAspectFit
        backgroundView.addSubview(managePreview)
        managePreview.snp.makeConstraints { make in
            make.width.equalTo(300)
            make.height.equalTo(144)
            make.top.equalToSuperview()
        }

        allowIcon.image = UDIcon.yesOutlined.withRenderingMode(.alwaysTemplate)
        allowIcon.tintColor = UIColor.ud.primaryOnPrimaryFill
        backgroundView.addSubview(allowIcon)
        allowIcon.snp.makeConstraints { make in
            make.leading.equalTo(20)
            make.top.equalTo(managePreview.snp.bottom).offset(23)
            make.width.height.equalTo(18)
        }

        let textColor = UIColor.ud.primaryOnPrimaryFill
        let titleFont = UIFont.systemFont(ofSize: 17, weight: .medium)
        let detailFont = UIFont.systemFont(ofSize: 14)
        allowTitle.text = BundleI18n.MailSDK.Mail_StrangerInbox_Allow_OnboardingMobile_Title
        allowTitle.textColor = textColor
        allowTitle.font = titleFont
        backgroundView.addSubview(allowTitle)
        allowTitle.snp.makeConstraints { make in
            make.left.equalTo(allowIcon.snp.right).offset(4)
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalTo(allowIcon)
        }

        allowDetail.numberOfLines = 0
        allowDetail.text = BundleI18n.MailSDK.Mail_StrangerMail_StrangerEmailsFeaturePopUp_AllowSender
        allowDetail.textColor = textColor
        allowDetail.font = detailFont
        backgroundView.addSubview(allowDetail)
        allowDetail.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalTo(allowTitle.snp.bottom).offset(6)
        }

        rejectIcon.image = UDIcon.noOutlined.withRenderingMode(.alwaysTemplate)
        rejectIcon.tintColor = UIColor.ud.primaryOnPrimaryFill
        backgroundView.addSubview(rejectIcon)
        rejectIcon.snp.makeConstraints { make in
            make.leading.equalTo(20)
            make.top.equalTo(allowDetail.snp.bottom).offset(23)
            make.width.height.equalTo(18)
        }

        rejectTitle.text = BundleI18n.MailSDK.Mail_StrangerInbox_Reject_OnboardingMobile_Title
        rejectTitle.textColor = textColor
        rejectTitle.font = titleFont
        rejectTitle.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        backgroundView.addSubview(rejectTitle)
        rejectTitle.snp.makeConstraints { make in
            make.trailing.equalTo(20)
            make.centerY.equalTo(rejectIcon)
            make.left.equalTo(rejectIcon.snp.right).offset(4)
        }

        rejectDetail.numberOfLines = 0
        rejectDetail.text = BundleI18n.MailSDK.Mail_StrangerMail_StrangerEmailsFeaturePopUp_RejectSender
        rejectDetail.textColor = textColor
        rejectDetail.font = detailFont
        backgroundView.addSubview(rejectDetail)
        rejectDetail.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalTo(rejectTitle.snp.bottom).offset(6)
        }

        backgroundView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalTo(rejectDetail.snp.bottom).offset(24)
            make.height.equalTo(48)
            make.bottom.equalTo(backgroundView.snp.bottom).offset(-20)
        }

    }

    @objc
    func closeButtonClicked() {
        closeHandler?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
