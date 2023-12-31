//
//  AddrBookContactTableViewCell.swift
//  LarkContact
//
//  Created by mochangxing on 2020/7/13.
//

import UIKit
import Foundation
import LarkAddressBookSelector
import LarkSDKInterface
import LarkBizAvatar
import LarkMessengerInterface

final class AddrBookContactTableViewCell: UITableViewCell {
    private lazy var gradientThumbnailContainer: UIView = {
        let view = UIView(frame: .zero)
        view.layer.addSublayer(self.gradientLayer)
        view.layer.cornerRadius = Layout.thumbnailSize.width / 2
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var gradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = .zero
        gradientLayer.colors = [UIColor.ud.colorfulBlue.cgColor, UIColor.ud.B400.cgColor]
        gradientLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)))
        return gradientLayer
    }()

    private lazy var profileThumbnailView: UILabel = {
        let view = UILabel(frame: .zero)
        view.backgroundColor = UIColor.clear
        view.textAlignment = NSTextAlignment.center
        view.textColor = UIColor.ud.primaryOnPrimaryFill
        view.font = UIFont.boldSystemFont(ofSize: 19.5)
        return view
    }()

    private lazy var profileThumbnailImageView: BizAvatar = {
        let view = BizAvatar()
        view.layer.cornerRadius = AddrBookContactTableViewCell.Layout.thumbnailSize.width / 2
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = NSTextAlignment.left
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.textColor = UIColor.ud.N900
        label.font = UIFont.systemFont(ofSize: 17)
        return label
    }()

    private lazy var subTitleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = NSTextAlignment.left
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.textColor = UIColor.ud.N500
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    private lazy var rightButton: UIButton = {
        let rightButton = UIButton(frame: .zero)
        rightButton.layer.cornerRadius = Layout.rightCornerRadius
        rightButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        rightButton.addTarget(self, action: #selector(onButtonTapped), for: .touchUpInside)
        return rightButton
    }()

    var rightButtonTappedAction: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        setupBackgroundViews(highlightOn: true)
        self.layoutPageSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutPageSubviews() {
        self.contentView.addSubview(self.gradientThumbnailContainer)
        self.gradientThumbnailContainer.addSubview(self.profileThumbnailView)
        self.contentView.addSubview(self.profileThumbnailImageView)
        self.contentView.addSubview(self.nameLabel)
        self.contentView.addSubview(self.subTitleLabel)
        self.contentView.addSubview(self.rightButton)

        self.gradientThumbnailContainer.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(Layout.thumbnailLeftOffset)
            make.size.equalTo(Layout.thumbnailSize)
            make.centerY.equalToSuperview()
        }
        self.profileThumbnailView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.profileThumbnailImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(Layout.thumbnailLeftOffset)
            make.size.equalTo(Layout.thumbnailSize)
            make.centerY.equalToSuperview()
        }
        self.rightButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-Layout.rightRightOffset)
            make.centerY.equalToSuperview()
            make.size.equalTo(Layout.rightButtonSize)
        }
        self.nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.profileThumbnailView.snp.right).offset(Layout.nameLabelLeftOffset)
            make.top.equalToSuperview().offset(Layout.nameLabelTopOffset)
            make.bottom.equalTo(self.profileThumbnailView.snp.centerY)
            make.right.equalTo(self.rightButton.snp.left).offset(-Layout.nameLabelRightOffset)
        }
        self.subTitleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.nameLabel)
            make.right.equalTo(self.nameLabel)
            make.top.equalTo(self.nameLabel.snp.bottom)
            make.bottom.equalToSuperview().offset(-Layout.subTitleLabelBottomOffset)
        }

        self.layoutIfNeeded()
        self.gradientLayer.frame = self.profileThumbnailView.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.profileThumbnailImageView.isHidden = true
        self.gradientThumbnailContainer.isHidden = true
    }

    func setRightButtonEnable(_ enable: Bool) {
        rightButton.backgroundColor = enable ? UIColor.ud.primaryContentDefault : UIColor.ud.N00
        rightButton.setTitleColor(enable ? UIColor.ud.primaryOnPrimaryFill : UIColor.ud.N500, for: .normal)
        rightButton.isEnabled = enable
    }

    func setRightButtonTitle(_ title: String) {
        rightButton.setTitle(title, for: .normal)
    }

    func updateCell(viewModel: AddrBookContactCellViewModel) {
        switch viewModel.contactModel.contactType {
        case .using:
            updateContactPointUserInfo(viewModel.contactModel.usingContact)
        case .notYet:
            updateAddressBookContact(viewModel.contactModel.notYetContact)
        @unknown default: break
        }
    }

    private func updateAddressBookContact(_ notYetUsingContact: NotYetUsingContact?) {
        guard let contact = notYetUsingContact else {
            return
        }
        if let thumbnailProfileImage = contact.addressBookContact.thumbnailProfileImage {
            profileThumbnailImageView.image = thumbnailProfileImage
            gradientThumbnailContainer.isHidden = true
            profileThumbnailImageView.isHidden = false
        } else {
            profileThumbnailView.text = contact.addressBookContact.pinyinHead
            gradientThumbnailContainer.isHidden = false
            profileThumbnailImageView.isHidden = true
        }
        setRightButtonEnable(contact.inviteStatus == .invite)
        setRightButtonTitle(contact.inviteStatus == .invite ?
            BundleI18n.LarkContact.Lark_NewContacts_MobileContactsInviteToLarkButton :
            BundleI18n.LarkContact.Lark_NewContacts_MobileContactsInviteToLarkInvited)
        nameLabel.text = contact.addressBookContact.fullName
        switch contact.addressBookContactType {
        case .email:
            subTitleLabel.text = contact.addressBookContact.email
        case .phone:
            subTitleLabel.text = contact.addressBookContact.phoneNumber
        @unknown default: break
        }
    }

    private func updateContactPointUserInfo(_ usingContact: ContactPointUserInfo?) {
        guard let usingContact = usingContact else {
            return
        }
        gradientThumbnailContainer.isHidden = true
        profileThumbnailImageView.isHidden = false
        nameLabel.text = usingContact.userInfo.userName
        subTitleLabel.text = usingContact.userInfo.tenantName

        profileThumbnailImageView.setAvatarByIdentifier(usingContact.userInfo.userID,
        avatarKey: usingContact.userInfo.avatarKey,
        scene: .Chat,
        avatarViewParams: .init(sizeType: .size(AddrBookContactTableViewCell.Layout.thumbnailSize.width)))

        self.nameLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(self.profileThumbnailView.snp.right).offset(Layout.nameLabelLeftOffset)
            if usingContact.userInfo.tenantName.isEmpty {
                make.centerY.equalTo(self.profileThumbnailView)
            } else {
                make.top.equalToSuperview().offset(Layout.nameLabelTopOffset)
                make.bottom.equalTo(self.profileThumbnailView.snp.centerY)
            }
            make.right.equalTo(self.rightButton.snp.left).offset(-Layout.nameLabelRightOffset)
        }

        updateRightButton(usingContact.contactStatus)
    }

    func updateRightButton(_ contactStatus: UserContactStatus) {
        switch contactStatus {
        case .contactStatusNotFriend, .contactStatusRequestExpired:
            setRightButtonEnable(true)
            setRightButtonTitle(BundleI18n.LarkContact.Lark_NewContacts_FromMobileContactsAdd)
        case .contactPointFriend:
            setRightButtonEnable(false)
            setRightButtonTitle(BundleI18n.LarkContact.Lark_NewContacts_FromMobileContactsAdded)
        case .contactStatusRequest:
            setRightButtonEnable(false)
            setRightButtonTitle(BundleI18n.LarkContact.Lark_Legacy_Requested)
        case .contactStatusReceive:
            setRightButtonEnable(true)
            setRightButtonTitle(BundleI18n.LarkContact.Lark_Legacy_Agree)
        @unknown default: break
        }
    }

    @objc
    func onButtonTapped() {
        rightButtonTappedAction?()
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        setBackViewColor(highlighted ? UIColor.ud.fillHover : UIColor.ud.bgBody)
    }
}

extension AddrBookContactTableViewCell {
    enum Layout {
        static let thumbnailSize: CGSize = CGSize(width: 48, height: 48)
        static let thumbnailLeftOffset: CGFloat = 16

        static let nameLabelLeftOffset: CGFloat = 12
        static let nameLabelRightOffset: CGFloat = 16
        static let nameLabelTopOffset: CGFloat = 12

        static let subTitleLabelRightOffset: CGFloat = 16
        static let subTitleLabelBottomOffset: CGFloat = 12

        static let rightButtonSize: CGSize = CGSize(width: 60, height: 28)
        static let rightCornerRadius: CGFloat = 4
        static let rightRightOffset: CGFloat = 10
        static let bottomBorderLeading: CGFloat = 76
    }
}
