//
//  ContactAddListCell.swift
//  LarkContact
//
//  Created by zhenning on 2020/07/10.
//

import UIKit
import Foundation
import LarkUIKit
import LarkButton
import LarkBizAvatar

typealias AddContactTapAction = (ContactItem) -> Void
final class ContactAddListCell: UITableViewCell {
    var contact: ContactItem = ContactItem(title: "", detail: nil) {
        didSet {
            updateContactInfo(contact: contact)
        }
    }

    var applyStatus: ContactApplyStatus = .contactStatusNotFriend {
        didSet {
            self.refreshAddButton(applyStatus: applyStatus)
        }
    }
    var addContactHandler: AddContactTapAction?

    private lazy var avatarView: BizAvatar = BizAvatar()
    /// title +  detail stackView
    private let textInfoStackView = UIStackView()
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.N900
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return titleLabel
    }()
    private lazy var detailLabel: UILabel = {
        let detailLabel = UILabel()
        detailLabel.textColor = UIColor.ud.N500
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        detailLabel.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        return detailLabel
    }()
    /// add button
    private lazy var addContactButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.layer.cornerRadius = Layout.buttonCornerRadius
        button.setTitle(BundleI18n.LarkContact.Lark_Legacy_Requested, for: UIControl.State.normal)
        button.addTarget(self, action: #selector(didTapAddContactButton), for: .touchUpInside)
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    func setupUI() {
        // Avatar
        addSubview(self.avatarView)
        self.avatarView.snp.makeConstraints { (make) in
            make.left.equalTo(Layout.contentInset.left)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: Layout.avatarLength, height: Layout.avatarLength))
        }

        textInfoStackView.axis = .vertical
        textInfoStackView.spacing = Layout.textLineInset
        textInfoStackView.alignment = .leading
        textInfoStackView.distribution = .fill
        contentView.addSubview(textInfoStackView)
        textInfoStackView.snp.makeConstraints({ (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(self.avatarView.snp.right).offset(Layout.textLeft)
        })

        textInfoStackView.addArrangedSubview(self.titleLabel)
        textInfoStackView.addArrangedSubview(self.detailLabel)

        // button
        addSubview(self.addContactButton)
        self.addContactButton.snp.makeConstraints { (make) in
            make.left.equalTo(textInfoStackView.snp.right).offset(Layout.addButtonLeft)
            make.right.equalTo(-Layout.contentInset.right)
            make.height.equalTo(Layout.addButtonSize.height)
            make.width.greaterThanOrEqualTo(Layout.addButtonSize.width)
            make.centerY.equalToSuperview()
        }
    }

    func updateContactInfo(contact: ContactItem) {
        let avatarKey = contact.avatarKey ?? ""
        let detailPrefix = BundleI18n.LarkContact.Lark_NewContacts_OnboardingMobileContactsMobile
        avatarView.setAvatarByIdentifier(contact.contactInfo?.userInfo.userID ?? "",
                                         avatarKey: avatarKey,
                                         scene: .Chat,
                                         avatarViewParams: .init(sizeType: .size(ContactAddListCell.Layout.avatarLength)))
        self.titleLabel.text = contact.title
        self.detailLabel.text = detailPrefix + (contact.detail ?? "")
        refreshAddButton(applyStatus: contact.applyStatus ?? .contactStatusNotFriend)
    }

    func refreshAddButton(applyStatus: ContactApplyStatus) {
        var addButtonTitle = BundleI18n.LarkContact.Lark_Legacy_Requested
        var titleColor = UIColor.ud.N00
        var backgroundColor = UIColor.ud.colorfulBlue
        switch applyStatus {
        case .contactStatusNotFriend:
            addButtonTitle = BundleI18n.LarkContact.Lark_Legacy_Add
            titleColor = UIColor.ud.N00
            backgroundColor = UIColor.ud.colorfulBlue
        case .contactStatusRequest:
            addButtonTitle = BundleI18n.LarkContact.Lark_Legacy_Requested
            titleColor = UIColor.ud.N500
            backgroundColor = UIColor.ud.N00
        }
        self.addContactButton.setTitle(addButtonTitle, for: UIControl.State.normal)
        self.addContactButton.setTitleColor(titleColor, for: UIControl.State.normal)
        self.addContactButton.backgroundColor = backgroundColor
    }

    @objc
    func didTapAddContactButton() {
        addContactHandler?(self.contact)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ContactAddListCell {
    enum Layout {
        static let contentInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        static let avatarLeft: CGFloat = 16
        static let textLeft: CGFloat = 12
        static let textLineInset: CGFloat = 3
        static let avatarLength: CGFloat = 48
        static let addButtonLeft: CGFloat = 10
        static let addButtonSize: CGSize = CGSize(width: 60, height: 28)
        static let buttonCornerRadius: CGFloat = 4
    }
}
