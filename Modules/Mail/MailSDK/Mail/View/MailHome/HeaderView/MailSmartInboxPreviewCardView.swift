//
//  MailSmartInboxPreviewCardView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/3/7.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignFont
import UIKit

protocol MailSmartInboxPreviewCardViewDelegate: AnyObject {
    func didClickPreviewCard()
    func closePreviewCard()
}

class MailSmartInboxPreviewCardView: UIView {
    weak var delegate: MailSmartInboxPreviewCardViewDelegate?

    lazy var backgroundView: UIControl = {
        let mask = UIControl()
        mask.addTarget(self, action: #selector(backgroundClick), for: .touchUpInside)
        return mask
    }()

    var inboxIcon: UIImageView = {
        let inboxIcon = UIImageView()
        inboxIcon.image = UDIcon.inboxOutlined.withRenderingMode(.alwaysTemplate)
        inboxIcon.tintColor = UIColor.ud.iconN2
        return inboxIcon
    }()

    var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UDFont.body1
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.isUserInteractionEnabled = false
        return titleLabel
    }()

    var subTitleLabel: UILabel = {
        let subTitleLabel = UILabel()
        subTitleLabel.font = UIFont.systemFont(ofSize: 14)
        subTitleLabel.textColor = UIColor.ud.textTitle
        subTitleLabel.isUserInteractionEnabled = false
        return subTitleLabel
    }()

    var closeButton: UIButton = {
        let closeButton = UIButton()
        closeButton.setImage(UDIcon.closeOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.imageEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        closeButton.tintColor = UIColor.ud.iconN2
        closeButton.addTarget(self, action: #selector(closeButtonClicked), for: .touchUpInside)
        return closeButton
    }()
    var infoContainer: UIStackView = {
        let infoContainer = UIStackView()
        infoContainer.axis = .horizontal
        infoContainer.spacing = 8
        infoContainer.alignment = .center
        infoContainer.isUserInteractionEnabled = false
        return infoContainer
    }()
    var sepView: UIView = {
        let sepView = UIView()
        sepView.backgroundColor = UIColor.ud.lineDividerDefault.withAlphaComponent(0.15)
        sepView.isUserInteractionEnabled = false
        return sepView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func backgroundClick() {
        delegate?.didClickPreviewCard()
    }

    @objc
    func closeButtonClicked() {
        delegate?.closePreviewCard()
    }

    private func setupViews() {
        backgroundColor = UIColor.ud.bgBodyOverlay
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        addSubview(inboxIcon)
        inboxIcon.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.width.height.equalTo(16)
            make.centerY.equalToSuperview()
        }
        addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(48)
            make.centerY.right.equalToSuperview()
        }
        infoContainer.addArrangedSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 56, height: 20))
        }
        infoContainer.addArrangedSubview(sepView)
        sepView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 1, height: 14))
            make.top.equalTo(3)
            make.bottom.equalTo(-3)
            make.centerY.equalToSuperview()
        }
        infoContainer.addArrangedSubview(subTitleLabel)
        subTitleLabel.snp.makeConstraints { (make) in
            make.height.equalTo(20)
            make.centerY.right.equalToSuperview()
        }
        addSubview(infoContainer)
        infoContainer.snp.makeConstraints { (make) in
            make.left.equalTo(inboxIcon.snp.right).offset(8)
            make.right.equalTo(-48)
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: 44)
    }

    @discardableResult
    func config(_ labelID: String) -> Bool {
        if labelID == Mail_LabelId_Other {
            inboxIcon.image = UDIcon.inboxOutlined.withRenderingMode(.alwaysTemplate)
            titleLabel.text = BundleI18n.MailSDK.Mail_SmartInbox_Others
            let titleWidth = titleLabel.text?.getTextWidth(font: UDFont.body1, height: 20) ?? 56
            titleLabel.snp.updateConstraints { (make) in
                make.size.equalTo(CGSize(width: titleWidth, height: 20))
            }
            return true
        } else if labelID == Mail_LabelId_Important {
            inboxIcon.image = UDIcon.priorityOutlined.withRenderingMode(.alwaysTemplate)
            titleLabel.text = BundleI18n.MailSDK.Mail_SmartInbox_Important
            let titleWidth = titleLabel.text?.getTextWidth(font: UDFont.body1, height: 20) ?? 56
            titleLabel.snp.updateConstraints { (make) in
                make.size.equalTo(CGSize(width: titleWidth, height: 20))
            }
            return true
        }
        return false
    }

    @discardableResult
    func configFromInfos(_ fromNames: [String]) -> Bool {
        var subtitleString = ""
        for (index, fromName) in fromNames.enumerated() {
            subtitleString += index == 0 ? fromName : ", \(fromName)"
        }
        if subtitleString == subTitleLabel.text {
            return true
        } else {
            subTitleLabel.text = subtitleString
            return true
        }
    }
}
