//
//  PersonalLinkView.swift
//  LarkContact
//
//  Created by liuxianyu on 2021/9/17.
//

import Foundation
import UIKit
import LarkUIKit
import LarkCore
import UniverseDesignToast
import RichLabel
import ByteWebImage
import LarkBizAvatar
import LarkAccountInterface
import LarkContainer

final class PersonalLinkView: UIView {
    private let containerView: UIView = UIView()
    private let headContent: UIView = UIView()
    private let avatarView: BizAvatar = BizAvatar()
    private let nameLabel: UILabel = UILabel()
    private let companyLabel: UILabel = UILabel()

    private let personalLinkContent: UIView = UIView()
    private let personalLinkBackgroundView: UIView = UIView()
    private let personalLinkMessageLabel: UILabel = UILabel()

    private let errorContentView: UIView = UIView()
    private let errorImageView: UIImageView = UIImageView()
    private let errorMessageLabel: UILabel = UILabel()
    private let retryButton: UIButton = UIButton()
    private let userResolver: UserResolver
    private lazy var currentUserId: String = {
        return self.userResolver.userID
    }()

    var onRetry: (() -> Void)?

    init(resolver: UserResolver) {
        self.userResolver = resolver
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        setupBaseView()
        setupHeaderView()
        setupPersonalLinkContentView()
        setupErrorContentView()
    }

    func setup(cardInfo: InviteAggregationInfo) {
        nameLabel.text = cardInfo.name
        companyLabel.text = cardInfo.tenantName

        avatarView.setAvatarByIdentifier(currentUserId,
                                         avatarKey: cardInfo.avatarKey,
                                         scene: .Contact,
                                         avatarViewParams: .init(sizeType: .size(Cons.avatarSize)))

        setupLinkMessage(cardInfo.externalExtraInfo?.linkInviteData.inviteMsg)
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
                with: CGSize(width: Cons.linkBgViewWidth - 24, height: CGFloat(MAXFLOAT)),
                options: .usesLineFragmentOrigin,
                attributes: attributes, context: nil)
            let height = ceil(rect.height)

            personalLinkMessageLabel.attributedText = attr
            personalLinkMessageLabel.numberOfLines = 0
            personalLinkMessageLabel.snp.updateConstraints { maker in
                maker.height.equalTo(height)
            }

            personalLinkBackgroundView.snp.updateConstraints { (maker) in
                maker.height.equalTo(height + 24)
            }
            personalLinkContent.snp.updateConstraints { (maker) in
                maker.height.equalTo(48 + height + Cons.containerBottomInset)
            }
        }
    }

    func updateContentView(_ showError: Bool) {
        containerView.snp.remakeConstraints { (maker) in
            maker.top.equalToSuperview().inset(Display.width < 375 ? Cons.containerTopInset * 0.5 : Cons.containerTopInset)
            maker.centerX.equalToSuperview()
            maker.width.equalTo(Cons.containerWidth)
            maker.bottom.equalTo(showError ? errorContentView.snp.bottom : personalLinkContent.snp.bottom)
            maker.bottom.equalToSuperview().inset(Display.width < 375 ? Cons.containerTopInset * 0.5 : Cons.containerTopInset)
        }

        containerView.isHidden = false
        errorContentView.isHidden = !showError
        personalLinkContent.isHidden = showError
    }

    @objc
    private func retry() {
        errorContentView.isHidden = true
        onRetry?()
    }

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
        headContent.backgroundColor = UIColor.ud.bgFloat
        containerView.addSubview(headContent)
        headContent.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().inset(Cons.headViewTopInset)
            maker.left.right.equalToSuperview().inset(20)
            maker.height.equalTo(Cons.headViewHeight)
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

    private func setupPersonalLinkContentView() {
        containerView.addSubview(personalLinkContent)
        personalLinkContent.backgroundColor = UIColor.ud.bgFloat
        personalLinkContent.snp.makeConstraints { (maker) in
            maker.top.equalTo(headContent.snp.bottom)
            maker.left.right.equalToSuperview()
            maker.height.equalTo(24 + Cons.containerBottomInset)
        }

        personalLinkBackgroundView.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.05)
        personalLinkBackgroundView.clipsToBounds = true
        personalLinkBackgroundView.layer.cornerRadius = 8
        personalLinkContent.addSubview(personalLinkBackgroundView)
        personalLinkBackgroundView.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(24)
            maker.centerX.equalToSuperview()
            maker.width.equalTo(Cons.linkBgViewWidth)
            maker.height.equalTo(0)
        }

        personalLinkMessageLabel.numberOfLines = 0
        personalLinkBackgroundView.addSubview(personalLinkMessageLabel)
        personalLinkMessageLabel.snp.makeConstraints { (maker) in
            maker.top.bottom.left.right.equalToSuperview().inset(12)
            maker.height.equalTo(0)
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
        errorMessageLabel.text = BundleI18n.LarkContact.Lark_Chat_FailedToLoadChatLink
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

extension PersonalLinkView {
    enum Cons {
        static var scale: CGFloat { Display.width < 375 ? Display.width / 375.0 : 1.0 }
        static var avatarSize: CGFloat { 48 }
        static var linkBgViewWidth: CGFloat { floor(303 * scale) }
        static var logoViewSize: CGFloat { floor(40 * scale) }
        static var headViewHeight: CGFloat { 50 }
        static var headViewTopInset: CGFloat { Display.pad ? 20 : floor(40 * scale) }
        static var containerTopInset: CGFloat { Display.pad ? 16 : floor(72 * scale) }
        static var containerBottomInset: CGFloat { floor(48 * scale) }
        static var containerWidth: CGFloat { floor(343 * scale) }
    }
}
