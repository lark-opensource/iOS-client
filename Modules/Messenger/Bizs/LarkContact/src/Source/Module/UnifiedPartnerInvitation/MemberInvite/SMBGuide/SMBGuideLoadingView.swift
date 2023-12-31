//
//  SMBGuideLoadingView.swift
//  LarkContact
//
//  Created by bytedance on 2022/4/11.
//

import UIKit
import Foundation
import SnapKit
import UniverseDesignLoading
import UniverseDesignColor

final class SMBGuideLoadingView: UIView {

    public init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var iconView = UDLoading.loadingImageView(lottieResource: nil)

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkContact.Lark_Shared_OnboardingOrientation_Loading_Text
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private func setupUI() {
        self.backgroundColor = UIColor.ud.bgFloat
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.height.equalTo(120)
            make.centerY.equalToSuperview().offset(-30)
        }
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(iconView.snp.bottom).offset(8)
        }
    }
}
