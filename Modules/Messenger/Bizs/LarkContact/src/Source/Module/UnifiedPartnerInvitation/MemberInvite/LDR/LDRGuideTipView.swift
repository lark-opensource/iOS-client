//
//  LDRGuideTipView.swift
//  LarkContact
//
//  Created by mochangxing on 2021/4/2.
//

import UIKit
import Foundation
import SnapKit

final class LDRGuideTipView: UIView {

    lazy var containerView: UIView = {
        let view = UIView()
        return view
    }()

    lazy var iconView: UIImageView = {
        let iconView = UIImageView(image: Resources.ldr_tips_icon)
        return iconView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = .center
        let tip = BundleI18n.LDR.Lark_Guide_TeamCreate3SuccessTitle
        let attributedText = NSMutableAttributedString(string: tip,
                                                       attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        label.attributedText = attributedText
        return label
    }()

    lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.ud.textCaption
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = .center
        let subtip = BundleI18n.LDR.Lark_Guide_TeamCreate3SuccessSubTitle()
        let attributedText = NSMutableAttributedString(string: subtip,
                                                       attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        label.attributedText = attributedText
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(containerView)
        containerView.addSubview(iconView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subTitleLabel)
        containerView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalToSuperview()
        }

        iconView.snp.makeConstraints { (make) in
            make.top.centerX.equalToSuperview()
            make.width.height.equalTo(120)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(iconView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.centerX.equalToSuperview()
        }
        subTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(55)
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
