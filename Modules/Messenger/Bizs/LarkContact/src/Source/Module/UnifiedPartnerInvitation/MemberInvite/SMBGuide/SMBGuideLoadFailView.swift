//
//  SMBGuideLoadFailView.swift
//  LarkContact
//
//  Created by bytedance on 2022/4/11.
//

import UIKit
import Foundation
import SnapKit
import UniverseDesignColor

final class SMBGuideLoadFailView: UIView {

    public init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var closeButtonClickEvent: (() -> Void)?

    lazy var iconImageView: UIImageView = UIImageView(image: Resources.ldr_tips_icon)

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkContact.Lark_Shared_OnboardingOrientation_Loaded_Text
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 6
        button.backgroundColor = UIColor.ud.primaryContentDefault
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        button.titleLabel?.textColor = UIColor.ud.primaryOnPrimaryFill
        button.addTarget(self, action: #selector(closeButtonDidClick), for: .touchUpInside)
        let title = BundleI18n.LarkContact.Lark_Shared_OnboardingOrientation_EnterFeishu_Button
        button.setTitle(title, for: .normal)
        return button
    }()

    @objc
    private func closeButtonDidClick() {
        if let block = closeButtonClickEvent {
            block()
        }
    }

    private func setupUI() {
        self.backgroundColor = UIColor.ud.bgFloat
        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-55)
            make.height.width.equalTo(120)
        }
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }
        addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.width.equalTo(163)
            make.height.equalTo(36)
        }
    }
}
