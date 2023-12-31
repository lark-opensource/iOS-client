//
//  ShareGroupLinkView.swift
//  LarkChatSetting
//
//  Created by 姜凯文 on 2020/4/20.
//

import Foundation
import UIKit
import LarkUIKit
import LarkCore
import UniverseDesignToast
import LarkBizAvatar
import RichLabel

final class ShareGroupLinkView: UIView {
    private let containerView: UIView = UIView()
    private let headContent: UIView = UIView()
    private var ownershipHeight: CGFloat = 0
    private var tipsHeight: CGFloat = 0
    private var linkMessageHeight: CGFloat = 0
    private let avatarView: BizAvatar = BizAvatar()
    private let nameLabel: UILabel = UILabel()
    private let companyLabel: UILabel = UILabel()

    private let groupLinkContent: UIView = UIView()
    private let groupLinkBackgroundView: UIView = UIView()
    private let groupLinkMessageLabel: UILabel = UILabel()
    private lazy var tipsLabel: LKLabel = {
        let tipsLabel = LKLabel()
        tipsLabel.textColor = UIColor.ud.textPlaceholder
        tipsLabel.backgroundColor = .clear
        tipsLabel.textAlignment = .center
        tipsLabel.font = .systemFont(ofSize: 12)
        tipsLabel.autoDetectLinks = false
        tipsLabel.numberOfLines = 0
        // 根据 https://bytedance.feishu.cn/docx/VpZTdl1IioCrENxfWakcPcrwnFo 替换为 byWordWrapping
        tipsLabel.lineBreakMode = .byWordWrapping
        return tipsLabel
    }()
    private lazy var updateTimeButton: UIButton = {
        let text = BundleI18n.LarkChatSetting.Lark_Group_ChangeQRcodeValidity
        let button = UIButton(type: .custom)
        button.setTitle(text, for: .normal)
        button.setTitleColor(UIColor.ud.textLinkNormal, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.isHidden = true
        return button
    }()
    private let ownershipLabel: UILabel = UILabel()

    private let errorContentView: UIView = UIView()
    private let errorImageView: UIImageView = UIImageView()
    private let errorMessageLabel: UILabel = UILabel()
    private let retryButton: UIButton = UIButton()

    var hud: UDToast?

    var onRetry: (() -> Void)?

    var setExpireTime: (() -> Void)?

    init() {
        super.init(frame: .zero)

        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        setupBaseView()
        setupHeaderView()
        setupGroupLinkContentView()
        setupUpdateExpireTimeView()
        setupErrorContentView()
    }

    func updateContentView(_ showError: Bool) {
        hud?.remove()

        containerView.snp.remakeConstraints { (maker) in
            maker.top.equalToSuperview().inset(Cons.containerTopInsetAutoLayout)
            maker.centerX.equalToSuperview()
            maker.width.equalTo(Cons.containerWidth)
            maker.bottom.equalTo(showError ? errorContentView.snp.bottom : groupLinkContent.snp.bottom)
        }

        containerView.isHidden = false
        errorContentView.isHidden = !showError
        groupLinkContent.isHidden = showError
        updateTimeButton.isHidden = showError
    }

    @objc
    private func retry() {
        errorContentView.isHidden = true
        onRetry?()
    }

    /// Set basic information
    func setup(
        with avatarKey: String?,
        entityId: String?,
        name: String?,
        tenantName: String?,
        ownership: String
    ) {
        if let key = avatarKey {
            avatarView.setAvatarByIdentifier(entityId ?? "", avatarKey: key, avatarViewParams: .init(sizeType: .size(Cons.avatarSize)))
        }
        nameLabel.text = name
        companyLabel.text = tenantName
        setupOwnership(ownership: ownership)
    }

    /// Set Link information
    func setupLinkInfo(_ linkString: String?, _ tip: String) {
        setupLinkMessage(linkString)
        setupTips(tip)
    }

    private func setupLinkMessage(_ linkString: String?) {
        if let string = linkString {
            let attr = NSMutableAttributedString(string: string)
            let style = NSMutableParagraphStyle()
            style.alignment = .left
            style.lineBreakMode = .byWordWrapping
            style.paragraphSpacing = 8
            style.minimumLineHeight = 22
            style.maximumLineHeight = 22
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 14),
                                                             .foregroundColor: UIColor.ud.textTitle,
                                                             .paragraphStyle: style]
            attr.addAttributes(attributes, range: NSRange(location: 0, length: attr.length))
            let rect = NSString(string: string).boundingRect(
                with: CGSize(width: Cons.groupLinkBGViewSize - 24, height: CGFloat(MAXFLOAT)),
                options: .usesLineFragmentOrigin,
                attributes: attributes, context: nil)
            let height = ceil(rect.height)

            groupLinkMessageLabel.attributedText = attr
            groupLinkMessageLabel.numberOfLines = 0
            groupLinkMessageLabel.snp.updateConstraints { maker in
                maker.height.equalTo(height)
            }
            linkMessageHeight = height
            groupLinkBackgroundView.snp.updateConstraints { maker in
                maker.height.equalTo(linkMessageHeight + 24)
            }
            groupLinkContent.snp.updateConstraints { maker in
                maker.height.equalTo(linkMessageHeight + tipsHeight + 32 +
                                     Cons.ownershipLabelTopInsetAutoLayout + ownershipHeight +
                                     Cons.containerBottomInsetAutoLayout)
            }
        }
    }

    private func setupTips(_ tip: String) {
        tipsLabel.text = tip
        tipsLabel.isHidden = tip.isEmpty
        if !tip.isEmpty {
            let height = tip.lu.height(font: tipsLabel.font, width: Cons.containerWidth - 40)
            tipsHeight = height
        } else {
            tipsHeight = 0
        }
        tipsLabel.snp.updateConstraints { maker in
            maker.height.equalTo(tipsHeight)
        }

        groupLinkContent.snp.updateConstraints { maker in
            maker.height.equalTo(linkMessageHeight + tipsHeight + 32 +
                                 Cons.ownershipLabelTopInsetAutoLayout + ownershipHeight +
                                 Cons.containerBottomInsetAutoLayout)
        }
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

        groupLinkContent.snp.updateConstraints { maker in
            maker.height.equalTo(linkMessageHeight + tipsHeight + 32 +
                                 Cons.ownershipLabelTopInsetAutoLayout + ownershipHeight +
                                 Cons.containerBottomInsetAutoLayout)
        }
    }

    @objc
    private func onSetExpireTime() {
        self.setExpireTime?()
    }

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
        headContent.backgroundColor = UIColor.ud.bgFloat
        containerView.addSubview(headContent)
        headContent.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
            maker.height.equalTo(Cons.headViewHeightAutoLayout)
        }

        headContent.addSubview(avatarView)
        avatarView.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().inset(20)
            maker.width.height.equalTo(Cons.avatarSize)
            maker.top.equalToSuperview().offset(Cons.avatarViewTopInsetAutoLayout)
        }

        nameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        nameLabel.textColor = UIColor.ud.textTitle
        headContent.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(avatarView.snp.right).offset(8)
            maker.right.equalToSuperview().offset(-20)
            maker.top.equalTo(avatarView.snp.top).offset(1)
            maker.height.equalTo(24)
        }

        companyLabel.font = UIFont.systemFont(ofSize: 12)
        companyLabel.textColor = UIColor.ud.textPlaceholder
        headContent.addSubview(companyLabel)
        companyLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(avatarView.snp.right).offset(8)
            maker.right.equalToSuperview().offset(-20)
            maker.top.equalTo(nameLabel.snp.bottom).offset(2)
            maker.height.equalTo(20)
        }
    }

    private func setupGroupLinkContentView() {
        containerView.addSubview(groupLinkContent)
        groupLinkContent.backgroundColor = UIColor.ud.bgFloat
        groupLinkContent.snp.makeConstraints { (maker) in
            maker.top.equalTo(headContent.snp.bottom)
            maker.left.right.equalToSuperview()
            maker.height.equalTo(0)
        }

        groupLinkBackgroundView.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.05)
        groupLinkBackgroundView.clipsToBounds = true
        groupLinkBackgroundView.layer.cornerRadius = 8
        groupLinkContent.addSubview(groupLinkBackgroundView)
        groupLinkBackgroundView.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview()
            maker.centerX.equalToSuperview()
            maker.width.equalTo(Cons.groupLinkBGViewSize)
            maker.height.equalTo(0)
        }

        groupLinkBackgroundView.addSubview(groupLinkMessageLabel)
        groupLinkMessageLabel.snp.makeConstraints { (maker) in
            maker.top.bottom.left.right.equalToSuperview().inset(12)
            maker.height.equalTo(0)
        }

        ownershipLabel.font = .systemFont(ofSize: 14)
        ownershipLabel.textColor = UIColor.ud.textTitle
        ownershipLabel.textAlignment = .center
        ownershipLabel.numberOfLines = 3
        ownershipLabel.lineBreakMode = .byTruncatingTail
        groupLinkContent.addSubview(ownershipLabel)
        ownershipLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(groupLinkBackgroundView.snp.bottom).offset(Cons.ownershipLabelTopInsetAutoLayout)
            maker.left.right.equalToSuperview().inset(20)
            maker.height.equalTo(0)
        }

        tipsLabel.numberOfLines = 2
        groupLinkContent.addSubview(tipsLabel)
        tipsLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(ownershipLabel.snp.bottom).offset(8)
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
            maker.top.equalToSuperview().offset(13)
            maker.width.height.equalTo(100)
        }

        errorMessageLabel.font = UIFont.systemFont(ofSize: 14)
        errorMessageLabel.textColor = UIColor.ud.textCaption
        errorMessageLabel.textAlignment = .center
        errorMessageLabel.text = BundleI18n.LarkChatSetting.Lark_Chat_FailedToLoadChatLink
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

extension ShareGroupLinkView {
    enum Cons {
        static var scale: CGFloat { Display.width < 375 ? Display.width / 375.0 : 1.0 }
        static var avatarSize: CGFloat { 48 }
        static var groupLinkBGViewSize: CGFloat { floor(303 * scale) }
        static var avatarViewTopInset: CGFloat { 32 }
        static var avatarViewTopInsetAutoLayout: CGFloat { (Display.width < 375 ? avatarViewTopInset * 0.5 : avatarViewTopInset) }
        static var headViewHeight: CGFloat { 104 }
        static var headViewHeightAutoLayout: CGFloat { (Display.width < 375 ? headViewHeight * 0.8 : headViewHeight) }
        static var containerTopInset: CGFloat { Display.pad ? 16 : floor(48 * scale) }
        static var containerTopInsetAutoLayout: CGFloat { (Display.width <= 375 ? containerTopInset * 0.2 : containerTopInset) }
        static var containerBottomInset: CGFloat { Display.pad ? 24 : floor(32 * scale) }
        static var containerBottomInsetAutoLayout: CGFloat { (Display.width < 375 ? containerBottomInset * 0.5 : containerBottomInset) }
        static var containerWidth: CGFloat { floor(343 * scale) }
        static var ownershipLabelTopInset: CGFloat { floor(24 * scale) }
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
