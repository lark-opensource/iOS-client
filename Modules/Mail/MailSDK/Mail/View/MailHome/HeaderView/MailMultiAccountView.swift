//
//  MailMultiAccountView.swift
//  MailSDK
//
//  Created by majx on 2020/5/25.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignIcon

protocol MailMultiAccountViewDelegate: AnyObject {
    func didClickMultiAccount()
    func didReverifySuccess()
}

class MailMultiAccountView: UIView {
    weak var delegate: MailMultiAccountViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        self.backgroundColor = UIColor.ud.bgBody
//        addSubview(topSeparator)
        addSubview(bottomSeparator)
        addSubview(arrowImageView)
        addSubview(mailAddressLabel)
        addSubview(badgeView)
//        topSeparator.snp.makeConstraints { (make) in
//            make.leading.trailing.equalTo(0)
//            make.height.equalTo(0.5)
//            make.top.equalTo(0)
//        }
        bottomSeparator.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(0)
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview()
        }
        arrowImageView.snp.makeConstraints { (make) in
           make.trailing.equalTo(-18)
           make.size.equalTo(CGSize(width: 16, height: 16))
           make.centerY.equalToSuperview()
        }
        badgeView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 6, height: 6))
            make.trailing.equalTo(-12)
            make.top.equalTo(12)
        }
        /// default hidden badge
        badgeView.isHidden = true
        mailAddressLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(16)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(-64)
        }
        mailAddressLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let tap = UITapGestureRecognizer(target: self, action: #selector(onClickSwitch))
        self.addGestureRecognizer(tap)
        self.isUserInteractionEnabled = true
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: 40)
    }

    func update(address: String, showBadge: (count: Int64, isRed: Bool)) {
        mailAddressLabel.text = address
        badgeView.isHidden = !(showBadge.count > 0)
        if showBadge.isRed {
            badgeView.backgroundColor = UIColor.ud.functionDangerContentDefault
        } else {
            badgeView.backgroundColor = UIColor.ud.iconDisable
        }
    }

    func update(showBadge: Bool, isRed: Bool) {
        badgeView.isHidden = !showBadge
        if isRed {
            badgeView.backgroundColor = UIColor.ud.functionDangerContentDefault
        } else {
            badgeView.backgroundColor = UIColor.ud.iconDisable
        }
    }

    @objc
    func onClickSwitch() {
        delegate?.didClickMultiAccount()
    }

    lazy var mailAddressLabel: UILabel = {
        let mailAddressLabel = UILabel()
        mailAddressLabel.textColor = UIColor.ud.textCaption
        mailAddressLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        mailAddressLabel.numberOfLines = 1
        mailAddressLabel.lineBreakMode = .byTruncatingTail
        return mailAddressLabel
    }()

    lazy var arrowImageView: UIImageView = {
        let arrowImageView = UIImageView()
        arrowImageView.image = UDIcon.switchOutlined.withRenderingMode(.alwaysTemplate)
        arrowImageView.tintColor = UIColor.ud.iconN2
        return arrowImageView
    }()

//    lazy var topSeparator: UIView = {
//        let separator = UIView()
//        separator.backgroundColor = UIColor.ud.N300
//        return separator
//    }()

    lazy var bottomSeparator: UIView = {
        let separator = UIView()
        separator.backgroundColor = UIColor.ud.lineDividerDefault.withAlphaComponent(0.15)
        return separator
    }()

    lazy var badgeView: UIView = {
        let badge = UIView()
        badge.backgroundColor = UIColor.ud.functionDangerContentDefault
        badge.clipsToBounds = true
        badge.layer.cornerRadius = 3
        return badge
    }()
}
