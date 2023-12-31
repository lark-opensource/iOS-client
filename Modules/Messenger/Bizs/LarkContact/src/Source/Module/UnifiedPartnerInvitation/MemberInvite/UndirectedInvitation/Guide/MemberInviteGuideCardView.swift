//
//  MemberInviteGuideCardView.swift
//  LarkContact
//
//  Created by shizhengyu on 2021/4/6.
//

import UIKit
import Foundation
import SnapKit
import QRCode
import LarkUIKit
import UniverseDesignColor
import UniverseDesignShadow

protocol MemberInviteGuideCardViewDelegate: AnyObject {
    func saveButtonDidClick()
    func shareButtonDidClick()
}

final class MemberInviteGuideCardView: UIView, CardBindable {
    lazy var shareSourceView = {
        return self.shareButton
    }()
    private weak var delegate: MemberInviteGuideCardViewDelegate?
    private let wrapperView = UIView()
    private let mainTitleLabel = UILabel()
    private let tenantLabel = UILabel()
    private let bgQrcodeView = UIView()
    private let qrcodeView = UIImageView()
    private let expireLabel = UILabel()
    private let saveButton = UIButton()
    private let shareButton = UIButton()

    init(delegate: MemberInviteGuideCardViewDelegate?) {
        self.delegate = delegate
        super.init(frame: .zero)
        layoutPageSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindWithModel(cardInfo: InviteAggregationInfo) {
        guard let memberInviteInfo = cardInfo.memberExtraInfo else { return }

        mainTitleLabel.text = BundleI18n.LarkContact.Lark_Guide_TeamCreateInviteQRFristHalf(cardInfo.name)
        tenantLabel.text = cardInfo.tenantName
        if let qrcodeImage = QRCodeTool.createQRImg(str: memberInviteInfo.urlForQRCode, size: UIScreen.main.bounds.size.width) {
            qrcodeView.image = qrcodeImage
            bgQrcodeView.backgroundColor = UIColor.ud.primaryOnPrimaryFill & UIColor.ud.N900
        }
        expireLabel.text = BundleI18n.LarkContact.Lark_Invitation_AddMembersShowQRCode_ExpirationTime(memberInviteInfo.expireDateDesc)
    }

    @objc
    func saveClick() {
        delegate?.saveButtonDidClick()
    }

    @objc
    func shareClick() {
        delegate?.shareButtonDidClick()
    }
}

private extension MemberInviteGuideCardView {
    func layoutPageSubviews() {
        backgroundColor = .clear
        self.layer.ud.setShadow(type: .s4Down)

        wrapperView.backgroundColor = UIColor.ud.bgFloat
        wrapperView.layer.cornerRadius = 16.0
        wrapperView.layer.masksToBounds = true
        addSubview(wrapperView)

        mainTitleLabel.textAlignment = .center
        mainTitleLabel.textColor = UIColor.ud.textTitle
        mainTitleLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        mainTitleLabel.numberOfLines = 1
        mainTitleLabel.lineBreakMode = .byTruncatingTail
        wrapperView.addSubview(mainTitleLabel)

        tenantLabel.textAlignment = .center
        tenantLabel.textColor = UIColor.ud.textTitle
        tenantLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        tenantLabel.numberOfLines = 1
        tenantLabel.lineBreakMode = .byTruncatingTail
        wrapperView.addSubview(tenantLabel)

        bgQrcodeView.backgroundColor = UIColor.ud.primaryOnPrimaryFill & UIColor.ud.N900
        bgQrcodeView.layer.cornerRadius = 4
        wrapperView.addSubview(bgQrcodeView)

        qrcodeView.layer.cornerRadius = 4.0
        qrcodeView.clipsToBounds = true
        qrcodeView.contentMode = .scaleAspectFit
        wrapperView.addSubview(qrcodeView)

        expireLabel.textAlignment = .center
        expireLabel.textColor = UIColor.ud.textPlaceholder
        expireLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        expireLabel.numberOfLines = 1
        expireLabel.lineBreakMode = .byTruncatingTail
        wrapperView.addSubview(expireLabel)

        saveButton.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.bgFloat), for: .normal)
        saveButton.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.N200), for: .highlighted)
        saveButton.setTitleColor(UIColor.ud.N900, for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        saveButton.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        saveButton.layer.borderWidth = 1.0
        saveButton.layer.cornerRadius = IGLayer.commonButtonRadius
        saveButton.layer.masksToBounds = true
        saveButton.setTitle(BundleI18n.LarkContact.Lark_Legacy_QrCodeSave, for: .normal)
        saveButton.addTarget(self, action: #selector(saveClick), for: .touchUpInside)
        wrapperView.addSubview(saveButton)

        shareButton.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.primaryContentDefault), for: .normal)
        shareButton.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.B600), for: .highlighted)
        shareButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        shareButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        shareButton.layer.cornerRadius = IGLayer.commonButtonRadius
        shareButton.layer.masksToBounds = true
        shareButton.setTitle(BundleI18n.LarkContact.Lark_Legacy_QrCodeShare, for: .normal)
        shareButton.addTarget(self, action: #selector(shareClick), for: .touchUpInside)
        wrapperView.addSubview(shareButton)

        wrapperView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        var offset = Display.pad ? 24 : 32
        mainTitleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(offset)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(28)
        }
        tenantLabel.snp.makeConstraints { (make) in
            make.top.equalTo(mainTitleLabel.snp.bottom).offset(0)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(28)
        }
        bgQrcodeView.backgroundColor = self.backgroundColor
        offset = Display.pad ? 16 : 24
        bgQrcodeView.snp.makeConstraints { (make) in
            make.top.equalTo(tenantLabel.snp.bottom).offset(offset - 10)
            make.width.height.equalTo(200)
            make.centerX.equalToSuperview()
        }
        qrcodeView.snp.makeConstraints { (make) in
            make.top.equalTo(tenantLabel.snp.bottom).offset(offset)
            make.width.height.equalTo(180)
            make.centerX.equalToSuperview()
        }
        expireLabel.snp.makeConstraints { (make) in
            make.top.equalTo(qrcodeView.snp.bottom).offset(offset)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        offset = Display.pad ? 16 : 52
        saveButton.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalTo(wrapperView.snp.centerX).offset(-8)
            make.height.equalTo(48)
            make.top.equalTo(expireLabel.snp.bottom).offset(offset)
            make.bottom.equalToSuperview().inset(16)
        }
        shareButton.snp.makeConstraints { (make) in
            make.leading.equalTo(wrapperView.snp.centerX).offset(8)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
            make.top.equalTo(expireLabel.snp.bottom).offset(offset)
            make.bottom.equalToSuperview().inset(16)
        }
    }
}
