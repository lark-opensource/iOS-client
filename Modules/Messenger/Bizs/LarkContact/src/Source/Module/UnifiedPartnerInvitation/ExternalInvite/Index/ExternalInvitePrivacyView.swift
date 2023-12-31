//
//  ExternalInvitePrivacyView.swift
//  LarkContact
//
//  Created by shizhengyu on 2021/1/13.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit

final class ExternalInvitePrivacyView: UIView {
    private let clickToEnable: () -> Void

    init(clickToEnable: @escaping () -> Void) {
        self.clickToEnable = clickToEnable
        super.init(frame: .zero)
        layoutPageSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layoutPageSubviews() {
        backgroundColor = UIColor.ud.N00

        let containerView = UIView()
        addSubview(containerView)

        let iconView = UIImageView()
        iconView.image = Resources.privary_protection
        containerView.addSubview(iconView)

        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.N900
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.text = BundleI18n.LarkContact.Lark_Chat_PrivacySettingOffQRCodeNoteTitle
        titleLabel.numberOfLines = 1
        containerView.addSubview(titleLabel)

        let descLabel = InsetsLabel(frame: .zero, insets: .zero)
        descLabel.textColor = UIColor.ud.N600
        descLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0
        descLabel.setText(
            text: BundleI18n.LarkContact.Lark_Chat_PrivacySettingOffQRCodeNoteContent(),
            lineSpacing: 4.0
        )
        containerView.addSubview(descLabel)

        let ctaButton = UIButton(type: .custom)
        ctaButton.backgroundColor = UIColor.ud.colorfulBlue
        ctaButton.setTitleColor(UIColor.ud.N00, for: .normal)
        ctaButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        ctaButton.layer.cornerRadius = 4.0
        ctaButton.layer.masksToBounds = true
        ctaButton.setTitle(BundleI18n.LarkContact.Lark_Chat_PrivacySettingOffQRCodeNoteButton, for: .normal)
        ctaButton.addTarget(self, action: #selector(clickToOpen), for: .touchUpInside)
        containerView.addSubview(ctaButton)

        containerView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        iconView.snp.makeConstraints { (make) in
            make.width.height.equalTo(100)
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(iconView.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        descLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        ctaButton.snp.makeConstraints { (make) in
            make.top.equalTo(descLabel.snp.bottom).offset(18)
            make.width.equalTo(88)
            make.height.equalTo(36)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    @objc
    func clickToOpen() {
        clickToEnable()
    }
}
