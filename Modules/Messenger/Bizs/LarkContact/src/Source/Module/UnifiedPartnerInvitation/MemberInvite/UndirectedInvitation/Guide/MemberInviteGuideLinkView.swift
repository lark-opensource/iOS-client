//
//  MemberInviteGuideLinkView.swift
//  LarkContact
//
//  Created by Aslan on 2021/6/27.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignColor

protocol MemberInviteGuideLinkViewDelegate: AnyObject {
    func copyButtonDidClick()
    func linkShareButtonDidClick()
}

final class MemberInviteGuideLinkView: UIView, CardBindable {
    lazy var shareSourceView = {
        return self.shareButton
    }()
    private weak var delegate: MemberInviteGuideLinkViewDelegate?
    private let wrapperView = UIView()
    private let expireLabel = UILabel()
    private let copyButton = UIButton()
    private let shareButton = UIButton()

    private lazy var linkView: UITextView = {
        let view = UITextView(frame: .zero)
        view.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        view.textAlignment = .left
        view.layer.cornerRadius = 6
        view.layer.masksToBounds = true
        view.isEditable = false
        view.isSelectable = false
        view.showsVerticalScrollIndicator = false
        return view
    }()

    init(delegate: MemberInviteGuideLinkViewDelegate?) {
        self.delegate = delegate
        super.init(frame: .zero)
        layoutPageSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindWithModel(cardInfo: InviteAggregationInfo) {
        guard let memberInviteInfo = cardInfo.memberExtraInfo else { return }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        // 根据 https://bytedance.feishu.cn/docx/VpZTdl1IioCrENxfWakcPcrwnFo 替换为 byWordWrapping
        paragraphStyle.lineBreakMode = .byWordWrapping

        let inviteMsg = BundleI18n.LarkContact.Lark_Guide_InviteLinkMsg(
            cardInfo.tenantName,
            memberInviteInfo.urlForLink
        )
        linkView.attributedText = NSAttributedString(
            string: inviteMsg,
            attributes: [.paragraphStyle: paragraphStyle,
                         .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                         .foregroundColor: UIColor.ud.textTitle]
        )
        expireLabel.text =
        BundleI18n.LarkContact.Lark_Invitation_AddMembersShowLink_ExpirationTime(
            memberInviteInfo.expireDateDesc
        )
    }

    @objc
    func copyClick() {
        delegate?.copyButtonDidClick()
    }

    @objc
    func shareClick() {
        delegate?.linkShareButtonDidClick()
    }
}

private extension MemberInviteGuideLinkView {
    func layoutPageSubviews() {
        self.layer.ud.setShadow(type: .s4Down)

        wrapperView.backgroundColor = UIColor.ud.bgFloat
        wrapperView.layer.cornerRadius = 16.0
        wrapperView.layer.masksToBounds = true
        addSubview(wrapperView)

        linkView.backgroundColor = UIColor.ud.N100
        linkView.textColor = UIColor.ud.textTitle
        wrapperView.addSubview(linkView)

        expireLabel.textAlignment = .center
        expireLabel.textColor = UIColor.ud.textPlaceholder
        expireLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        expireLabel.numberOfLines = 1
        expireLabel.lineBreakMode = .byTruncatingTail
        wrapperView.addSubview(expireLabel)

        copyButton.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.bgFloat), for: .normal)
        copyButton.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.N200), for: .highlighted)
        copyButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
        copyButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        copyButton.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        copyButton.layer.borderWidth = 1.0
        copyButton.layer.cornerRadius = 6.0
        copyButton.layer.masksToBounds = true
        copyButton.setTitle(BundleI18n.LarkContact.Lark_Legacy_Copy, for: .normal)
        copyButton.addTarget(self, action: #selector(copyClick), for: .touchUpInside)
        wrapperView.addSubview(copyButton)

        shareButton.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.primaryContentDefault), for: .normal)
        shareButton.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.B600), for: .highlighted)
        shareButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        shareButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        shareButton.layer.cornerRadius = 6.0
        shareButton.layer.masksToBounds = true
        shareButton.setTitle(BundleI18n.LarkContact.Lark_Legacy_QrCodeShare, for: .normal)
        shareButton.addTarget(self, action: #selector(shareClick), for: .touchUpInside)
        wrapperView.addSubview(shareButton)

        wrapperView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        linkView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(Display.pad ? 200 : 272)
        }
        expireLabel.snp.makeConstraints { (make) in
            make.top.equalTo(linkView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        copyButton.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalTo(wrapperView.snp.centerX).offset(-8)
            make.height.equalTo(48)
            make.top.equalTo(expireLabel.snp.bottom).offset(Display.pad ? 60 : 52)
            make.bottom.equalToSuperview().inset(16)
        }
        shareButton.snp.makeConstraints { (make) in
            make.leading.equalTo(wrapperView.snp.centerX).offset(8)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
            make.top.equalTo(expireLabel.snp.bottom).offset(Display.pad ? 60 : 52)
            make.bottom.equalToSuperview().inset(16)
        }
    }
}
