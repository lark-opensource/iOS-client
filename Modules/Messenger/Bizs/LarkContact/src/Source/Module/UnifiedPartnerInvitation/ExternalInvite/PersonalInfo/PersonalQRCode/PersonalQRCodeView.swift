//
//  PersonalQRCodeView.swift
//  LarkContact
//
//  Created by liuxianyu on 2021/9/17.
//

import Foundation
import LarkUIKit
import QRCode
import LKMetric
import Homeric
import ByteWebImage
import UniverseDesignColor
import LarkAppResources
import LarkBizAvatar
import LarkAccountInterface
import UIKit
import LarkContainer

final class PersonalQRCodeView: UIView {
    private let monitor = InviteMonitor()

    private let userResolver: UserResolver
    private let containerView: UIView = UIView()
    private let headContent: UIView = UIView()
    private let headerBgView: UIView = UIView()
    private let avatarView: BizAvatar = BizAvatar()
    private let nameLabel: UILabel = UILabel()
    private let companyLabel: UILabel = UILabel()
    private lazy var currentUserId: String = {
        return self.userResolver.userID
    }()

    private let qrCodeContentView: UIView = UIView()
    private let bgQrcodeView: UIView = UIView()
    private let qrCodeImageView: UIImageView = UIImageView()
    private let logoImageView: UIImageView = UIImageView()
    private lazy var bottomTipsLabel: UILabel = {
        let bottomTipsLabel = UILabel()
        bottomTipsLabel.textColor = UIColor.ud.textPlaceholder
        bottomTipsLabel.textAlignment = .center
        bottomTipsLabel.backgroundColor = .clear
        bottomTipsLabel.font = .systemFont(ofSize: 14)
        bottomTipsLabel.numberOfLines = 0
        bottomTipsLabel.lineBreakMode = .byWordWrapping
        bottomTipsLabel.text = BundleI18n.LarkContact.Lark_Profile_AddExternalContactQRCode_Desc
        return bottomTipsLabel
    }()

    private let errorContentView: UIView = UIView()
    private let errorImageView: UIImageView = UIImageView()
    private let errorMessageLabel: UILabel = UILabel()
    private let retryButton: UIButton = UIButton()

    var onRetry: (() -> Void)?

    init(resolver: UserResolver) {
        self.userResolver = resolver
        super.init(frame: .zero)

        setupBaseView()
        setupHeaderView()
        setupQRCodeContentView()
        setupErrorContentView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Set basic information
    func setup(cardInfo: InviteAggregationInfo) {
        nameLabel.text = cardInfo.name
        companyLabel.text = cardInfo.tenantName

        avatarView.setAvatarByIdentifier(currentUserId,
                                         avatarKey: cardInfo.avatarKey,
                                         scene: .Contact,
                                         avatarViewParams: .init(sizeType: .size(Cons.avatarSize)))

        let startTimeInterval = CACurrentMediaTime()
        var qrlinkGenUrl: String? = cardInfo.externalExtraInfo?.qrcodeInviteData.inviteURL
        monitor.startEvent(
            name: Homeric.UG_INVITE_EXTERNAL_NONDIRECTIONAL_LOAD_QRCODE,
            indentify: String(startTimeInterval),
            reciableEvent: .externalOrientationLoadQrcode
        )

        if let qrlinkGenUrl = qrlinkGenUrl,
           let qrcodeImage = QRCodeTool.createQRImg(str: qrlinkGenUrl, size: 220) {
            qrCodeImageView.image = qrcodeImage
            LKMetric.EN.loadQrCodeSuccess()
            monitor.endEvent(
                name: Homeric.UG_INVITE_EXTERNAL_NONDIRECTIONAL_LOAD_QRCODE,
                indentify: String(startTimeInterval),
                category: ["succeed": "true"],
                extra: [:],
                reciableState: .success,
                needNet: false,
                reciableEvent: .externalOrientationLoadQrcode
            )
        } else {
            LKMetric.EN.loadQrCodeFailed(errorMsg: cardInfo.externalExtraInfo?.qrcodeInviteData.inviteURL ?? "")
            monitor.endEvent(
                name: Homeric.UG_INVITE_EXTERNAL_NONDIRECTIONAL_LOAD_QRCODE,
                indentify: String(startTimeInterval),
                category: ["succeed": "false"],
                extra: [:],
                reciableState: .failed,
                needNet: false,
                reciableEvent: .externalOrientationLoadQrcode
            )
        }
    }

    func prepareScreenShot(enabled: Bool) -> UIView {
        if enabled {
            containerView.layer.cornerRadius = 0
        } else {
            containerView.layer.cornerRadius = 16
        }
        return containerView
    }

    func updateContentView(_ showError: Bool) {
        containerView.snp.remakeConstraints { (maker) in
            maker.top.equalToSuperview().inset(Display.width < 375 ? Cons.containerTopInset * 0.5 : Cons.containerTopInset)
            maker.centerX.equalToSuperview()
            maker.width.equalTo(Cons.containerWidth)
            maker.bottom.equalTo(showError ? errorContentView.snp.bottom : qrCodeContentView.snp.bottom)
            maker.bottom.equalToSuperview().inset(Display.width < 375 ? Cons.containerTopInset * 0.5 : Cons.containerTopInset)
        }

        containerView.isHidden = false
        errorContentView.isHidden = !showError
        qrCodeContentView.isHidden = showError
    }

    @objc
    private func retry() {
        errorContentView.isHidden = true
        onRetry?()
    }

    // MARK: - UI Setup
    private func setupBaseView() {
        self.backgroundColor = .clear
        containerView.isHidden = true
        containerView.backgroundColor = UIColor.ud.bgFloat
        containerView.layer.cornerRadius = 16
        containerView.layer.masksToBounds = true
        self.addSubview(containerView)
        containerView.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().inset(Display.width < 375 ? Cons.containerTopInset * 0.5 : Cons.containerTopInset)
            maker.centerX.equalToSuperview()
            maker.width.equalTo(Cons.containerWidth)
            maker.height.equalTo(0)
            maker.bottom.equalToSuperview().inset(Display.width < 375 ? Cons.containerTopInset * 0.5 : Cons.containerTopInset)
        }
    }

    private func setupHeaderView() {
        containerView.addSubview(headContent)
        headContent.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().inset(Cons.headViewTopInset)
            maker.left.right.equalToSuperview().inset(50)
            maker.height.equalTo(Cons.headViewHeight)
        }

        headContent.addSubview(headerBgView)
        headerBgView.snp.makeConstraints { (maker) in
            maker.left.right.top.bottom.equalToSuperview()
        }

        avatarView.layer.cornerRadius = Cons.avatarSize / 2
        avatarView.layer.masksToBounds = true
        headContent.addSubview(avatarView)
        avatarView.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview()
            maker.width.height.equalTo(Cons.avatarSize)
            maker.centerY.equalToSuperview()
        }

        nameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        nameLabel.textColor = UIColor.ud.textTitle
        headContent.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(avatarView.snp.right).offset(8)
            maker.right.equalToSuperview()
            maker.top.equalToSuperview().offset(1)
            maker.height.equalTo(24)
        }

        companyLabel.font = UIFont.systemFont(ofSize: 14)
        companyLabel.textColor = UIColor.ud.textPlaceholder
        headContent.addSubview(companyLabel)
        companyLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(avatarView.snp.right).offset(8)
            maker.right.equalToSuperview()
            maker.top.equalTo(nameLabel.snp.bottom).offset(2)
            maker.height.equalTo(20)
        }
    }

    private func setupQRCodeContentView() {
        containerView.addSubview(qrCodeContentView)
        qrCodeContentView.backgroundColor = UIColor.ud.bgFloat
        qrCodeContentView.snp.makeConstraints { (maker) in
            maker.top.equalTo(headContent.snp.bottom)
            maker.left.right.equalToSuperview()
            maker.height.equalTo(48 + Cons.bgQRCodeViewSize + Cons.containerBottomInset)
        }

        bgQrcodeView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        bgQrcodeView.layer.cornerRadius = 8
        bgQrcodeView.layer.masksToBounds = true
        qrCodeContentView.addSubview(bgQrcodeView)
        bgQrcodeView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(Cons.bgQRCodeViewSize)
        }

        qrCodeImageView.layer.cornerRadius = 2
        qrCodeImageView.clipsToBounds = true
        qrCodeImageView.layer.masksToBounds = true
        bgQrcodeView.addSubview(qrCodeImageView)
        qrCodeImageView.snp.makeConstraints { (maker) in
            maker.top.bottom.left.right.equalToSuperview().inset(8)
        }

        logoImageView.layer.cornerRadius = 4
        logoImageView.layer.masksToBounds = true
        logoImageView.backgroundColor = UDColor.primaryOnPrimaryFill
        logoImageView.image = AppResources.calendar_share_logo
        qrCodeImageView.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { (maker) in
            maker.centerX.centerY.equalToSuperview()
            maker.width.height.equalTo(Cons.logoViewSize)
        }

        qrCodeContentView.addSubview(bottomTipsLabel)
        bottomTipsLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(bgQrcodeView.snp.bottom).offset(16)
            maker.left.right.equalToSuperview().inset(20)
        }
    }

    private func setupErrorContentView() {
        containerView.addSubview(errorContentView)
        errorContentView.backgroundColor = UIColor.ud.bgFloat
        errorContentView.isHidden = true
        errorContentView.snp.makeConstraints { (maker) in
            maker.top.equalTo(headContent.snp.bottom)
            maker.left.right.equalToSuperview()
            maker.bottom.equalToSuperview()
        }

        errorImageView.image = Resources.profile_load_fail
        errorContentView.addSubview(errorImageView)
        errorImageView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(13)
            maker.width.height.equalTo(100)
        }

        errorMessageLabel.font = UIFont.systemFont(ofSize: 14)
        errorMessageLabel.textColor = UIColor.ud.textCaption
        errorMessageLabel.textAlignment = .center
        errorMessageLabel.text = BundleI18n.LarkContact.Lark_Legacy_QRCodeLoadFailed
        errorContentView.addSubview(errorMessageLabel)
        errorMessageLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(errorImageView.snp.bottom).offset(12)
            maker.centerX.equalToSuperview()
            maker.left.right.equalToSuperview().inset(20)
            maker.height.equalTo(22)
        }

        let title = BundleI18n.LarkContact.Lark_Legacy_QrCodeLoadAgain
        let font = UIFont.systemFont(ofSize: 16)
        retryButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
        retryButton.layer.cornerRadius = 6
        retryButton.layer.masksToBounds = true
        retryButton.layer.borderWidth = 1
        retryButton.ud.setLayerBorderColor(UIColor.ud.lineBorderComponent)
        retryButton.titleLabel?.font = font
        retryButton.titleLabel?.numberOfLines = 0
        retryButton.setTitle(title, for: .normal)
        retryButton.addTarget(self, action: #selector(retry), for: .touchUpInside)
        retryButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        errorContentView.addSubview(retryButton)
        retryButton.snp.makeConstraints { (maker) in
            maker.top.equalTo(errorMessageLabel.snp.bottom).offset(16)
            maker.centerX.equalToSuperview()
            maker.width.lessThanOrEqualToSuperview().offset(-20)
            maker.bottom.equalToSuperview().inset(73)
        }
    }
}

extension PersonalQRCodeView {
    enum Cons {
        static var scale: CGFloat { Display.width < 375 ? Display.width / 375.0 : 1.0 }
        static var avatarSize: CGFloat { 48 }
        static var bgQRCodeViewSize: CGFloat { floor(236 * scale) }
        static var logoViewSize: CGFloat { floor(40 * scale) }
        static var headViewHeight: CGFloat { 50 }
        static var headViewTopInset: CGFloat { Display.pad ? 20 : floor(40 * scale) }
        static var containerTopInset: CGFloat { Display.pad ? 16 : floor(72 * scale) }
        static var containerBottomInset: CGFloat { Display.pad ? 22 : floor(44 * scale) }
        static var containerWidth: CGFloat { floor(343 * scale) }
    }
}
