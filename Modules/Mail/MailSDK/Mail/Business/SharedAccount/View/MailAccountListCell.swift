//
//  MailMultiAccountCell.swift
//  MailSDK
//
//  Created by majx on 2020/6/1.
//

import Foundation
import UIKit
import LarkTag
import RxSwift
import LarkUIKit
import UniverseDesignBadge
import UniverseDesignIcon
import UniverseDesignFont

class MailAccountListCell: UITableViewCell {
    private var disposeBag: DisposeBag = DisposeBag()
    private var unreadCount: Int = 0
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        selectionStyle = .none
        contentView.addSubview(titleContainer)
        contentView.addSubview(markView)
        contentView.addSubview(badgeContainerView)
        contentView.addSubview(separator)
        titleContainer.addSubview(titleLabel)
        titleContainer.addSubview(accountTag)
        titleContainer.addSubview(migratingLabel)
        badgeContainerView.addSubview(badgeView)

        accountTag.snp.makeConstraints { (make) in
            make.width.equalTo(44)
            make.trailing.equalToSuperview()
            make.height.equalTo(18)
            make.centerY.equalToSuperview()
        }
        migratingLabel.snp.makeConstraints { make in
            make.width.equalTo(44)
            make.trailing.equalToSuperview()
            make.height.equalTo(18)
            make.centerY.equalToSuperview()
        }
        badgeContainerView.snp.makeConstraints { (make) in
            make.trailing.equalTo(-18)
            make.height.equalTo(16)
            make.centerY.equalToSuperview()
        }
        badgeView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        markView.snp.makeConstraints { (make) in
            make.trailing.equalTo(-16)
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
        }
        markView.isHidden = true
        separator.snp.makeConstraints { make in
            make.bottom.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.left.equalTo(16)
        }
        remakeTitleContainerConstraints()
        remakeTitleLabelConstraints()
    }

    func remakeTitleContainerConstraints() {
        titleContainer.snp.remakeConstraints { make in
            make.top.equalTo(13)
            make.bottom.equalTo(-13)
            make.leading.equalTo(16)
            if markView.isHidden && badgeContainerView.isHidden {
                make.trailing.lessThanOrEqualToSuperview().offset(-16)
            } else if !markView.isHidden {
                make.trailing.lessThanOrEqualTo(markView.snp.leading).offset(-8)
            } else {
                make.trailing.lessThanOrEqualTo(badgeContainerView.snp.leading).offset(-8)
            }
        }
    }

    func remakeTitleLabelConstraints() {
        titleLabel.snp.makeConstraints { (make) in
            make.top.leading.equalToSuperview()
            if accountTag.isHidden && migratingLabel.isHidden {
                make.trailing.equalToSuperview()
            } else if !accountTag.isHidden {
                if let width = accountTag.text?.getTextWidth(font: UIFont.systemFont(ofSize: 10, weight: .medium), height: 44) {
                    make.trailing.equalToSuperview().offset(-4-width-10)
                } else {
                    make.trailing.lessThanOrEqualTo(accountTag.snp.leading).offset(-4)
                }
            } else {
                if let width = migratingLabel.text?.getTextWidth(font: UIFont.systemFont(ofSize: 12), height: 44) {
                    make.trailing.equalToSuperview().offset(-4-width-10)
                } else {
                    make.trailing.lessThanOrEqualTo(migratingLabel.snp.leading).offset(-4)
                }
            }
            make.centerY.equalToSuperview()
        }
    }

    func update(account: MailAccountInfo) {
        if account.address.isEmpty || account.userType == .newUser {
            titleLabel.text = BundleI18n.MailSDK.Mail_Mailbox_BusinessEmailDidntLink
        } else {
            titleLabel.text = account.address
        }

        update(unreadCount: Int(account.unread), notification: account.notification)

        if account.isOAuthAccount {
            if account.status == .valid || (account.userType == .tripartiteClient && account.status == nil) {
                accountTag.isHidden = true
                badgeContainerView.isHidden = false
            } else if account.status == .notApplicable {
                accountTag.isHidden = false
                badgeContainerView.isHidden = true
                accountTag.text = BundleI18n.MailSDK.Mail_Mailbox_DidntLinkTag
            } else if account.status == .expired || account.status == .deleted {
                accountTag.isHidden = false
                badgeContainerView.isHidden = true
                accountTag.text = Store.settingData.mailClient ? BundleI18n.MailSDK.Mail_ThirdClient_Expired : BundleI18n.MailSDK.Mail_Mailbox_AccountsExpired
            } else {
                accountTag.isHidden = false
                badgeContainerView.isHidden = true
                accountTag.text = BundleI18n.MailSDK.Mail_Mailbox_DidntLinkTag
            }
        } else {
            accountTag.isHidden = true
        }
        migratingLabel.isHidden = !account.isMigrating
        if let width = accountTag.text?.getTextWidth(font: UIFont.systemFont(ofSize: 10, weight: .medium), height: 44), !accountTag.isHidden {
            accountTag.snp.updateConstraints { (make) in
                make.width.equalTo(width + 10)
            }
        }
        
        if let width = migratingLabel.text?.getTextWidth(font: UIFont.systemFont(ofSize: 12), height: 44), !migratingLabel.isHidden {
            migratingLabel.snp.updateConstraints { (make) in
                make.width.equalTo(width + 10)
            }
        }
        remakeTitleContainerConstraints()
        remakeTitleLabelConstraints()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.backgroundColor = isHighlighted ? UIColor.ud.fillHover : UIColor.ud.bgBody
    }

    private func update(unreadCount: Int, notification: Bool) {
        self.unreadCount = unreadCount
        let color: UIColor = notification ? UIColor.ud.functionDangerContentDefault : UIColor.ud.iconDisable
        badgeView.config.style = .custom(color)
        badgeView.config.number = self.unreadCount
        badgeView.config.maxNumber = 999
        badgeView.config.contentStyle = .custom(UIColor.ud.primaryOnPrimaryFill)
        badgeContainerView.isHidden = !(self.unreadCount > 0)
    }

    var isPopover: Bool = false
    var showSeparator: Bool = true {
        didSet {
            separator.isHidden = !showSeparator
        }
    }

    override var isSelected: Bool {
        didSet {
            titleLabel.textColor = isSelected ? UIColor.ud.primaryContentDefault : UIColor.ud.textTitle
            contentView.backgroundColor = UIColor.ud.bgBody
            if isPopover {
                markView.isHidden = true
                if isSelected {
                    titleLabel.textColor = UIColor.ud.primaryContentDefault
                    contentView.backgroundColor = UIColor.ud.fillHover
                    badgeContainerView.isHidden = true
                } else {
                    badgeContainerView.isHidden = !(self.unreadCount > 0)
                }
            } else {
                markView.isHidden = !isSelected
                if isSelected {
                    badgeContainerView.isHidden = true
                } else {
                    badgeContainerView.isHidden = !(self.unreadCount > 0)
                }
            }
            remakeTitleContainerConstraints()
        }
    }

    lazy var titleContainer: UIView = {
        let titleContainer = UIView()
        return titleContainer
    }()

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        return titleLabel
    }()

    lazy var markView: UIImageView = {
        let markView = UIImageView(image: UDIcon.doneOutlined.withRenderingMode(.alwaysTemplate))
        markView.tintColor = UIColor.ud.primaryContentDefault
        return markView
    }()

    // UDBadge会根据配置的数据是否为空，自动修改isHidden属性；即不可直接使用或修改UDBadge的isHidden属性，否则会与组件内部逻辑产生冲突异常，组件修改影响面大，业务暂时绕开修改isHidden的修改
    lazy var badgeContainerView = UIView()
    lazy var badgeView: UDBadge = {
        let badgeLabel = UDBadge(config: .number)
        return badgeLabel
    }()

    lazy var accountTag: PaddingUILabel = {
        let accountTag = PaddingUILabel()
        accountTag.color = UIColor.ud.functionDangerFillSolid02
        accountTag.paddingLeft = 5
        accountTag.paddingRight = 5
        accountTag.layer.cornerRadius = 4
        accountTag.clipsToBounds = true
        accountTag.textColor = UIColor.ud.functionDangerContentPressed
        accountTag.text = BundleI18n.MailSDK.Mail_Mailbox_AccountsExpired
        accountTag.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        return accountTag
    }()

    lazy var separator: UIView = {
        let separator = UIView()
        separator.backgroundColor = UIColor.ud.lineDividerDefault.withAlphaComponent(0.15)
        return separator
    }()
    
    lazy var migratingLabel: PaddingUILabel = {
        let label = PaddingUILabel()
        label.color = UIColor.ud.udtokenTagBgOrange.withAlphaComponent(0.15)
        label.textColor = UIColor.ud.udtokenTagTextSOrange
        label.paddingLeft = 5
        label.paddingRight = 5
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 1
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        label.text = BundleI18n.MailSDK.Mail_PublicMailbox_ToBeMigrated
        label.isHidden = true
        return label
    }()
}
