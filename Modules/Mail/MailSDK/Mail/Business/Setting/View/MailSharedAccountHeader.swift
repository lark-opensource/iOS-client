//
//  MailSharedAccountHeader.swift
//  MailSDK
//
//  Created by majx on 2020/9/15.
//

import Foundation
import UIKit
import SnapKit
import LarkAlertController
import UniverseDesignIcon

protocol MailSharedAccountHeaderViewDelegate: AnyObject {
    func deleteBanner()
}

class MailSharedAccountHeaderView: UIView {
    var showDeleteBtn: Bool = false
    var iconTop: Bool = false
    weak var delegate: MailSharedAccountHeaderViewDelegate? = nil
    init(frame: CGRect, showDeleteBtn: Bool = false, iconTop: Bool = false) {
        super.init(frame: frame)
        self.showDeleteBtn = showDeleteBtn
        self.iconTop = iconTop
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(text: String) {
        titleLabel.text = text
    }

    func setupViews() {
        backgroundColor = UIColor.ud.primaryFillSolid02
        addSubview(iconImgView)
        addSubview(titleLabel)
        if self.showDeleteBtn {
            addSubview(deleteBtn)
            deleteBtn.isHidden = false
        } else {
            deleteBtn.isHidden = true
        }
        let iconImgTop = self.iconTop
        iconImgView.snp.makeConstraints { (make) in
            make.leading.equalTo(16)
            make.size.equalTo(CGSize(width: 16, height: 16))
            if iconImgTop {
                make.top.equalTo(7)
            } else {
                make.centerY.equalToSuperview()
            }
        }

        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(iconImgView.snp.trailing).offset(8)
            make.trailing.equalTo(-16)
            make.centerY.equalToSuperview()
        }
        titleLabel.text = BundleI18n.MailSDK.Mail_Mailbox_PublicMailboxSettingSync

        if self.showDeleteBtn {
            deleteBtn.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.size.equalTo(CGSize(width: 12, height: 12))
                make.trailing.equalTo(-16)
            }
        }
    }

    func updateTitleColor(color: UIColor) {
        titleLabel.textColor = color
    }

    @objc
    private func deleteBannerClick() {
        self.delegate?.deleteBanner()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: 48)
    }

    lazy var iconImgView: UIImageView = {
        let iconImgView = UIImageView()
        iconImgView.image = UDIcon.infoColorful
        return iconImgView
    }()

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.primaryContentDefault
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        return titleLabel
    }()

    lazy var deleteBtn: UIButton = {
        let closeButton = UIButton()
        closeButton.setImage(Resources.smartInbox_card_close.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.addTarget(self, action: #selector(deleteBannerClick), for: .touchUpInside)
        closeButton.tintColor = UIColor.ud.iconN3
        closeButton.hitTestEdgeInsets = UIEdgeInsets(top: -12, left: -12, bottom: -12, right: -12)
        return closeButton
    }()
}
