//
//  LDRGuideView.swift
//  LarkContact
//
//  Created by mochangxing on 2021/4/2.
//

import UIKit
import Foundation
import UniverseDesignColor
import UniverseDesignFont
import SnapKit
import LarkUIKit

typealias LDRGuideViewTapHandler = () -> Void

final class LDRGuideView: UIView {

    var flowOption: LDRFlowOption?
    var tapHandler: LDRGuideViewTapHandler?

    public var isSelected: Bool

    lazy var checkbox: Checkbox = {
        let checkbox = Checkbox()
        checkbox.onCheckColor = UIColor.ud.primaryOnPrimaryFill
        checkbox.onFillColor = UIColor.ud.primaryContentDefault
        checkbox.offFillColor = UIColor.ud.udtokenComponentOutlinedBg
        checkbox.strokeColor = UIColor.ud.N500
        checkbox.lineWidth = 1.5
        checkbox.isUserInteractionEnabled = false
        return checkbox
    }()

    lazy var iconView: UIImageView = {
        let iconView = UIImageView()
        iconView.backgroundColor = UIColor.ud.fillTag
        iconView.layer.cornerRadius = 20
        iconView.clipsToBounds = true
        return iconView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.body1
        label.text = BundleI18n.LDR.Lark_Guide_TeamCreate3SuccessTitle
        return label
    }()

    lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 12)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    override init(frame: CGRect) {
        self.isSelected = true
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgFloatOverlay
        self.layer.cornerRadius = 8
        addSubview(checkbox)
        checkbox.setOn(on: true, animated: false)
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(subTitleLabel)

        checkbox.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.centerY.equalTo(self.snp.centerY)
            make.width.height.equalTo(20)
        }

        iconView.snp.makeConstraints { (make) in
            make.leading.equalTo(checkbox.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(20)
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(19)
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(22)
        }
        subTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom)
            make.leading.equalTo(titleLabel.snp.leading)
            make.trailing.equalToSuperview().inset(16)
        }

        self.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(flowOptionTap))
        self.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc
    private func flowOptionTap() {
        self.isSelected = !self.isSelected
        self.checkbox.setOn(on: self.isSelected, animated: true)
        if let tapHandler = self.tapHandler {
            tapHandler()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
