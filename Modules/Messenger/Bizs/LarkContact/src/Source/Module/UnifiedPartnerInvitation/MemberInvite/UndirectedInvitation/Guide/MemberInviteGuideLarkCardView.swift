//
//  MemberInviteGuideLarkCardView.swift
//  LarkContact
//
//  Created by Aslan on 2021/6/27.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignColor

protocol MemberInviteGuideLarkCardViewDelegate: AnyObject {
    func larkShareButtonDidClick()
    func sendEmailButtonDicClick()
    func invitePhoneButtonDidClick()
}

final class MemberInviteGuideLarkCardView: UIView {
    private weak var delegate: MemberInviteGuideLarkCardViewDelegate?
    private let wrapperView = UIView()
    lazy var shareSourceView = {
        return self.shareLinkButton
    }()
    lazy var shareLinkButton: UIButton = {
        var button = UIButton()
        button.setTitle(BundleI18n.LarkContact.Lark_Guide_TeamCreate2MobileTeamLink, for: .normal)
        button.backgroundColor = UIColor.ud.primaryContentDefault
        button.setImage(
            Resources.icon_share_link,
            for: .normal
        )
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.layer.cornerRadius = 6
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.addTarget(self, action: #selector(shareClick), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -3, bottom: 0, right: 3)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: -3)
        return button
    }()

    lazy var emailInviteButton: UIButton = {
        var button = UIButton()
        button.setTitle(BundleI18n.LarkContact.Lark_Guide_TeamCreate2MobileEmail, for: .normal)
        button.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        let icon = Resources.icon_mail_invite.ud.withTintColor(UIColor.ud.iconN1)
        button.setImage(icon, for: .normal)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.layer.cornerRadius = 6
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        button.layer.borderWidth = 1.0
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.addTarget(self, action: #selector(emailInviteClick), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -3, bottom: 0, right: 3)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: -3)
        return button
    }()

    lazy var contactInviteButton: UIButton = {
        var button = UIButton()
        button.setTitle(BundleI18n.LarkContact.Lark_Guide_TeamCreate2MobilePhoneContacts, for: .normal)
        button.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        let icon = Resources.icon_contacts_invite
            .ud.withTintColor(UIColor.ud.iconN1)
        button.setImage(icon, for: .normal)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.layer.cornerRadius = 6
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        button.layer.borderWidth = 1.0
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.addTarget(self, action: #selector(contactInviteClick), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -3, bottom: 0, right: 3)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: -3)
        return button
    }()

    init(delegate: MemberInviteGuideLarkCardViewDelegate?) {
        self.delegate = delegate
        super.init(frame: .zero)
        layoutPageSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func shareClick() {
        delegate?.larkShareButtonDidClick()
    }

    @objc
    func emailInviteClick() {
        delegate?.sendEmailButtonDicClick()
    }

    @objc
    func contactInviteClick() {
        delegate?.invitePhoneButtonDidClick()
    }
}

private extension MemberInviteGuideLarkCardView {
    func layoutPageSubviews() {
        backgroundColor = .clear

        addSubview(wrapperView)

        wrapperView.addSubview(shareLinkButton)
        wrapperView.addSubview(emailInviteButton)
        wrapperView.addSubview(contactInviteButton)

        wrapperView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        shareLinkButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }
        emailInviteButton.snp.makeConstraints { (make) in
            make.top.equalTo(shareLinkButton.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }
        contactInviteButton.snp.makeConstraints { (make) in
            make.top.equalTo(emailInviteButton.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
            make.bottom.equalToSuperview()
        }
    }
}
