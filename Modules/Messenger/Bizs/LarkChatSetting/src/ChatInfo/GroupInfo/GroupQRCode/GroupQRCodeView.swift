//
//  GroupQRCodeView.swift
//  Action
//
//  Created by K3 on 2018/9/20.
//

import Foundation
import UIKit
import LarkUIKit
import LarkCore
import LarkFoundation
import RxCocoa
import RxSwift
import UniverseDesignToast
import QRCode
import LarkBizAvatar
import RichLabel
import LKCommonsLogging
import LarkAppResources
import UniverseDesignShadow

final class GroupQRCodeView: UIView {
    private let containerView: UIView = UIView()
    private let headContent: UIView = UIView()
    private let headerBgView: GroupQRCodeHeaderBGView = GroupQRCodeHeaderBGView()
    private let avatarView: BizAvatar = BizAvatar()
    private var ownershipHeight: CGFloat = 0
    private var bottomTipsLabelHeight: CGFloat = 0
    private let nameLabel: UILabel = UILabel()
    private let companyLabel: UILabel = UILabel()

    private let qrCodeContentView: UIView = UIView()
    private let bgQrcodeView: UIView = UIView()
    private let qrCodeImageView: UIImageView = UIImageView()
    private let logoImageView: UIImageView = UIImageView()
    private lazy var bottomTipsLabel: LKLabel = {
        let bottomTipsLabel = LKLabel()
        bottomTipsLabel.textColor = UIColor.ud.textPlaceholder
        bottomTipsLabel.textAlignment = .center
        bottomTipsLabel.backgroundColor = .clear
        bottomTipsLabel.font = .systemFont(ofSize: 12)
        bottomTipsLabel.autoDetectLinks = false
        bottomTipsLabel.numberOfLines = 0
        bottomTipsLabel.lineBreakMode = .byWordWrapping
        return bottomTipsLabel
    }()
    private let ownershipLabel: UILabel = UILabel()
    private lazy var updateTimeButton: UIButton = {
        let text = BundleI18n.LarkChatSetting.Lark_Group_ChangeQRcodeValidity
        let button = UIButton(type: .custom)
        button.setTitle(text, for: .normal)
        button.setTitleColor(UIColor.ud.textLinkNormal, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.isHidden = true
        return button
    }()

    private let errorContentView: UIView = UIView()
    private let errorImageView: UIImageView = UIImageView()
    private let errorMessageLabel: UILabel = UILabel()
    private let retryButton: UIButton = UIButton()

    var hud: UDToast?

    var onRetry: (() -> Void)?

    var setExpireTime: (() -> Void)?

    static let logger = Logger.log(GroupQRCodeView.self, category: "Module.LarkChatSetting.GroupQRCodeView")

    init(isPopOver: Bool) {
        super.init(frame: .zero)

        setupBaseView()
        setupHeaderView()
        setupQRCodeContentView()
        setupUpdateExpireTimeView()
        setupErrorContentView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Set basic information
    func setup(with avatarKey: String?,
               entityId: String?,
               name: String?,
               tenantName: String?,
               ownership: String
    ) {
        if let key = avatarKey {
            avatarView.setAvatarByIdentifier(entityId ?? "",
                                             avatarKey: key,
                                             avatarViewParams: .init(sizeType: .size(Cons.avatarSize)),
                                             backgroundColorWhenError: UIColor.ud.N300,
                                             completion: { [weak self] result in
                                                 switch result {
                                                 case .success(let imageResult):
                                                     if let image = imageResult.image {
                                                         self?.headerBgView.setHeaderBGImageWithOriginImage(image, entityId: entityId ?? "", key: key, finish: nil)
                                                     }
                                                 case .failure(let error):
                                                     Self.logger.error("refreshData error \(key) error: \(error)")
                                                 }
                                             })
        }
        nameLabel.text = name
        companyLabel.text = tenantName
        setupOwnership(ownership: ownership)
    }

    /// Set QR information
    func setupQRCodeInfo(_ qrCodeString: String?, _ tip: String) {
        if let string = qrCodeString {
            qrCodeImageView.image = QRCodeTool.createQRImg(str: string, size: 220)
            bgQrcodeView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        }
        setupTips(tip, true)
    }

    func setupTips(_ tip: String, _ updateExpireEnabled: Bool) {
        let attr = NSMutableAttributedString(string: tip)
        updateTimeButton.isHidden = !updateExpireEnabled

        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.lineBreakMode = .byWordWrapping
        style.minimumLineHeight = 18
        style.maximumLineHeight = 18
        attr.addAttributes([.font: UIFont.systemFont(ofSize: 12),
                            .foregroundColor: UIColor.ud.textPlaceholder,
                            .paragraphStyle: style],
                           range: NSRange(location: 0, length: attr.length))
        bottomTipsLabel.attributedText = attr

        let height = tip.lu.height(font: bottomTipsLabel.font, width: Cons.containerWidth - 40)
        bottomTipsLabel.snp.updateConstraints { maker in
            maker.height.equalTo(height)
        }
        bottomTipsLabelHeight = height
        qrCodeContentView.snp.updateConstraints { (maker) in
            maker.height.equalTo(Cons.ownershipLabelTopInsetAutoLayout + ownershipHeight +
                                 Cons.bgQrcodeViewTopInset + Cons.bgQRCodeViewSize +
                                 Cons.bottomTipsLabelTopInset + bottomTipsLabelHeight +
                                 Cons.containerBottomInsetAutoLayout)
        }
    }

    func prepareScreenShot(enabled: Bool) -> UIView {
        containerView.layer.cornerRadius = enabled ? 0 : 12
        return containerView
    }

    @objc
    private func onSetExpireTime() {
        self.setExpireTime?()
    }

    func setupOwnership(ownership: String) {
        ownershipLabel.text = ownership
        ownershipLabel.isHidden = ownership.isEmpty
        if !ownership.isEmpty {
            let height = ownership.lu.height(font: ownershipLabel.font, width: Cons.containerWidth - 40)
            ownershipHeight = height
        } else {
            ownershipHeight = 0
        }

        ownershipLabel.snp.updateConstraints { maker in
            maker.height.equalTo(ownershipHeight)
        }
        qrCodeContentView.snp.updateConstraints { (maker) in
            maker.height.equalTo(Cons.ownershipLabelTopInsetAutoLayout + ownershipHeight +
                                 Cons.bgQrcodeViewTopInset + Cons.bgQRCodeViewSize +
                                 Cons.bottomTipsLabelTopInset + bottomTipsLabelHeight +
                                 Cons.containerBottomInsetAutoLayout)
        }
    }

    func updateContentView(_ showError: Bool) {
        hud?.remove()

        containerView.snp.remakeConstraints { (maker) in
            maker.top.equalToSuperview().inset(Cons.containerTopInsetAutoLayout)
            maker.centerX.equalToSuperview()
            maker.width.equalTo(Cons.containerWidth)
            maker.bottom.equalTo(showError ? errorContentView.snp.bottom : qrCodeContentView.snp.bottom)
        }

        containerView.isHidden = false
        errorContentView.isHidden = !showError
        qrCodeContentView.isHidden = showError
        updateTimeButton.isHidden = showError
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
        containerView.layer.cornerRadius = 12
        containerView.layer.masksToBounds = true
        self.addSubview(containerView)
        containerView.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().inset(Cons.containerTopInsetAutoLayout)
            maker.centerX.equalToSuperview()
            maker.width.equalTo(Cons.containerWidth)
            maker.height.equalTo(0)
        }
    }

    private func setupHeaderView() {
        containerView.addSubview(headContent)
        headContent.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
            maker.height.equalTo(Cons.headViewHeight)
        }

        headContent.addSubview(headerBgView)
        headerBgView.snp.makeConstraints { (maker) in
            maker.left.right.top.bottom.equalToSuperview()
        }

        headContent.addSubview(avatarView)
        avatarView.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(20)
            maker.width.height.equalTo(Cons.avatarSize)
            maker.centerY.equalToSuperview()
        }

        nameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        nameLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        nameLabel.layer.ud.setShadowColor(UDShadowColorTheme.s2DownColor)
        nameLabel.layer.shadowOpacity = 0.12
        nameLabel.layer.shadowRadius = 6
        nameLabel.layer.shadowOffset = CGSize(width: 0, height: 2)
        headContent.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(avatarView.snp.right).offset(12)
            maker.right.equalToSuperview().offset(-20)
            maker.centerY.equalTo(avatarView).offset(20 - Cons.avatarSize / 2)
            maker.height.equalTo(24)
        }

        companyLabel.font = UIFont.systemFont(ofSize: 14)
        companyLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        companyLabel.layer.ud.setShadowColor(UDShadowColorTheme.s2DownColor)
        companyLabel.layer.shadowOpacity = 0.12
        companyLabel.layer.shadowRadius = 6
        companyLabel.layer.shadowOffset = CGSize(width: 0, height: 2)
        headContent.addSubview(companyLabel)
        companyLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(avatarView.snp.right).offset(12)
            maker.right.equalToSuperview().offset(-20)
            maker.centerY.equalTo(avatarView).offset(46 - Cons.avatarSize / 2)
            maker.height.equalTo(20)
        }
    }

    private func setupQRCodeContentView() {
        containerView.addSubview(qrCodeContentView)
        qrCodeContentView.backgroundColor = UIColor.ud.bgFloat
        qrCodeContentView.snp.makeConstraints { (maker) in
            maker.top.equalTo(headContent.snp.bottom)
            maker.left.right.equalToSuperview()
            maker.height.equalTo(Cons.ownershipLabelTopInsetAutoLayout + ownershipHeight +
                                 Cons.bgQrcodeViewTopInset + Cons.bgQRCodeViewSize +
                                 Cons.bottomTipsLabelTopInset + bottomTipsLabelHeight +
                                 Cons.containerBottomInsetAutoLayout)
        }

        bgQrcodeView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        bgQrcodeView.layer.cornerRadius = 8
        bgQrcodeView.layer.masksToBounds = true
        qrCodeContentView.addSubview(bgQrcodeView)
        bgQrcodeView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(Cons.bgQrcodeViewTopInset)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(Cons.bgQRCodeViewSize)
        }

        qrCodeImageView.layer.cornerRadius = 2
        qrCodeImageView.clipsToBounds = true
        bgQrcodeView.addSubview(qrCodeImageView)
        qrCodeImageView.snp.makeConstraints { (maker) in
            maker.top.bottom.left.right.equalToSuperview().inset(8)
        }

        logoImageView.layer.cornerRadius = 4
        logoImageView.layer.masksToBounds = true
        logoImageView.image = AppResources.calendar_share_logo
        qrCodeImageView.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { (maker) in
            maker.centerX.centerY.equalToSuperview()
            maker.width.height.equalTo(Cons.logoViewSize)
        }

        ownershipLabel.font = .systemFont(ofSize: 14)
        ownershipLabel.textColor = UIColor.ud.textTitle
        ownershipLabel.textAlignment = .center
        ownershipLabel.numberOfLines = 3
        ownershipLabel.lineBreakMode = .byTruncatingTail
        qrCodeContentView.addSubview(ownershipLabel)
        ownershipLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(bgQrcodeView.snp.bottom).offset(Cons.ownershipLabelTopInsetAutoLayout)
            maker.left.right.equalToSuperview().inset(20)
            maker.height.equalTo(0)
        }

        bottomTipsLabel.numberOfLines = 2
        qrCodeContentView.addSubview(bottomTipsLabel)
        bottomTipsLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(ownershipLabel.snp.bottom).offset(Cons.bottomTipsLabelTopInset)
            maker.left.right.equalToSuperview().inset(20)
            maker.height.equalTo(0)
        }
    }

    private func setupUpdateExpireTimeView() {
        updateTimeButton.addTarget(self, action: #selector(onSetExpireTime), for: .touchUpInside)
        self.addSubview(updateTimeButton)
        updateTimeButton.snp.makeConstraints { (maker) in
            maker.height.equalTo(22)
            maker.left.right.equalToSuperview().inset(40)
            maker.top.equalTo(containerView.snp.bottom).offset(Cons.updateTimeButtonTopInsetAutoLayout)
            maker.bottom.equalToSuperview().inset(Cons.containerTopInsetAutoLayout)
        }
    }

    private func setupErrorContentView() {
        containerView.addSubview(errorContentView)
        errorContentView.backgroundColor = UIColor.ud.bgFloat
        errorContentView.isHidden = true
        errorContentView.snp.makeConstraints { (maker) in
            maker.top.equalTo(headContent.snp.bottom)
            maker.left.right.equalToSuperview()
            maker.height.equalTo(Cons.errorImageViewTopInsetAutoLayout +
                                 Cons.retryButtonBottomInsetAutoLayout + 186)
        }

        errorImageView.image = Resources.load_fail
        errorContentView.addSubview(errorImageView)
        errorImageView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(Cons.errorImageViewTopInsetAutoLayout)
            maker.width.height.equalTo(100)
        }

        errorMessageLabel.font = UIFont.systemFont(ofSize: 14)
        errorMessageLabel.textColor = UIColor.ud.textCaption
        errorMessageLabel.textAlignment = .center
        errorMessageLabel.text = BundleI18n.LarkChatSetting.Lark_Legacy_QRCodeLoadFailed
        errorContentView.addSubview(errorMessageLabel)
        errorMessageLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(errorImageView.snp.bottom).offset(12)
            maker.centerX.equalToSuperview()
            maker.left.right.equalToSuperview().inset(20)
            maker.height.equalTo(22)
        }

        let title = BundleI18n.LarkChatSetting.Lark_Legacy_QrCodeLoadAgain
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

extension GroupQRCodeView {
    enum Cons {
        static var scale: CGFloat { Display.width < 375 ? Display.width / 375.0 : 1.0 }
        static var avatarSize: CGFloat { 64 }
        static var bgQRCodeViewSize: CGFloat { floor(148 * scale) }
        static var logoViewSize: CGFloat { floor(24 * scale) }
        static var headViewHeight: CGFloat { floor(112 * scale) }
        static var containerTopInset: CGFloat { Display.pad ? 16 : floor(48 * scale) }
        static var containerTopInsetAutoLayout: CGFloat { (Display.width <= 375 ? containerTopInset * 0.2 : containerTopInset) }
        static var containerBottomInset: CGFloat { Display.pad ? 24 : floor(32 * scale) }
        static var containerBottomInsetAutoLayout: CGFloat { (Display.width < 375 ? containerBottomInset * 0.5 : containerBottomInset) }
        static var containerWidth: CGFloat { floor(343 * scale) }
        static var bgQrcodeViewTopInset: CGFloat { floor(24 * scale) }
        static var ownershipLabelTopInset: CGFloat { Display.pad ? 24 : floor(32 * scale) }
        static var ownershipLabelTopInsetAutoLayout: CGFloat { (Display.width < 375 ? ownershipLabelTopInset * 0.5 : ownershipLabelTopInset) }
        static var bottomTipsLabelTopInset: CGFloat { floor(8 * scale) }
        static var updateTimeButtonTopInset: CGFloat { floor(24 * scale) }
        static var updateTimeButtonTopInsetAutoLayout: CGFloat { (Display.width <= 375 ? updateTimeButtonTopInset * 0.5 : updateTimeButtonTopInset) }
        static var errorImageViewTopInset: CGFloat { floor(45 * scale) }
        static var errorImageViewTopInsetAutoLayout: CGFloat { (Display.width < 375 ? errorImageViewTopInset * 0.5 : errorImageViewTopInset) }
        static var retryButtonBottomInset: CGFloat { floor(45 * scale) }
        static var retryButtonBottomInsetAutoLayout: CGFloat { (Display.width < 375 ? retryButtonBottomInset * 0.5 : retryButtonBottomInset) }
    }
}
