//
//  InviteLinkCard.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/12/15.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import ByteWebImage
import LarkBizAvatar
import LarkAccountInterface
import LarkContainer

final class InviteLinkCard: UIView, CardBindable {
    let scenes: UnifiedNoDirectionalScenes
    var switchToQRCodeHandler: (() -> Void)?
    let disposeBag = DisposeBag()

    private let userResolver: UserResolver
    private lazy var currentUserId: String = {
        return self.userResolver.userID
    }()

    init(scenes: UnifiedNoDirectionalScenes, resolver: UserResolver) {
        self.scenes = scenes
        self.userResolver = resolver
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgFloat
        layoutPageSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindWithModel(cardInfo: InviteAggregationInfo) {
        nameLabel.text = cardInfo.name
        companyLabel.text = cardInfo.tenantName

        avatarView.setAvatarByIdentifier(currentUserId,
                                         avatarKey: cardInfo.avatarKey,
                                         scene: .Contact,
                                         avatarViewParams: .init(sizeType: .size(avatarSize)))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        // 根据 https://bytedance.feishu.cn/docx/VpZTdl1IioCrENxfWakcPcrwnFo 替换为 byWordWrapping
        paragraphStyle.lineBreakMode = .byWordWrapping
        switch scenes {
        case .parent:
            if let parentExtra = cardInfo.parentExtraInfo {
                linkView.attributedText = NSAttributedString(
                    string: parentExtra.inviteMsg,
                    attributes: [.paragraphStyle: paragraphStyle,
                                 .font: UIFont.boldSystemFont(ofSize: 14),
                                 .foregroundColor: UIColor.ud.textTitle]
                )
                expireLabel.text = "\(BundleI18n.LarkContact.Lark_Invitation_AddMembersExpiredTime)\(parentExtra.expireDateDesc)"
            }
        case .external:
            if let externalInviteInfo = cardInfo.externalExtraInfo {
                linkView.attributedText = NSAttributedString(
                    string: externalInviteInfo.linkInviteData.inviteMsg,
                    attributes: [.paragraphStyle: paragraphStyle,
                                 .font: UIFont.boldSystemFont(ofSize: 14),
                                 .foregroundColor: UIColor.ud.textTitle]
                )
            }
        }
    }

    private func layoutPageSubviews() {
        addSubview(avatarView)
        addSubview(infoView)
        infoView.addSubview(nameLabel)
        infoView.addSubview(companyLabel)
        addSubview(switchToQRCodeView)
        addSubview(contentWrapper)
        contentWrapper.addSubview(linkView)
        switch scenes {
        case .parent:
            contentWrapper.addSubview(expireLabel)
        case .external:
            contentWrapper.addSubview(tipLabel)
        }

        avatarView.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(20)
            make.height.width.equalTo(avatarSize)
        }
        infoView.snp.makeConstraints { (make) in
            make.centerY.equalTo(avatarView)
            make.leading.equalTo(avatarView.snp.trailing).offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }
        companyLabel.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.bottom.equalToSuperview()
        }
        switchToQRCodeView.snp.makeConstraints { (make) in
            make.top.trailing.equalToSuperview()
            make.width.height.equalTo(60)
        }
        switch scenes {
        case .parent:
            contentWrapper.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(avatarView.snp.bottom).offset(42)
                make.height.equalTo(200)
            }
            linkView.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(16)
                make.top.equalToSuperview()
                make.height.equalTo(140)
            }
            expireLabel.snp.makeConstraints { (make) in
                make.top.equalTo(linkView.snp.bottom).offset(16)
                make.centerX.equalToSuperview()
            }
        case .external:
            contentWrapper.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(avatarView.snp.bottom).offset(50)
                make.height.equalTo(300)
            }
            linkView.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview().inset(16)
                make.top.equalToSuperview()
                make.height.equalTo(230)
            }
            tipLabel.snp.makeConstraints { (make) in
                make.top.equalTo(linkView.snp.bottom).offset(12)
                make.leading.trailing.equalToSuperview().inset(24)
                make.height.equalTo(40)
            }
        }
    }

    private let avatarSize: CGFloat = 48
    private lazy var avatarView: BizAvatar = BizAvatar()

    private lazy var infoView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .left
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var companyLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var switchToQRCodeView: UIImageView = {
        let view = UIImageView()
        view.image = Resources.switch_to_qrcode
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer()
        tap.rx.event.asDriver().drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.switchToQRCodeHandler?()
        }).disposed(by: disposeBag)
        view.addGestureRecognizer(tap)
        return view
    }()

    private lazy var contentWrapper: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var linkView: UITextView = {
        let view = UITextView(frame: .zero)
        view.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        view.textColor = UIColor.ud.textTitle
        view.font = UIFont.systemFont(ofSize: 14)
        view.backgroundColor = UIColor.ud.bgFloatOverlay
        view.textAlignment = .left
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        view.isEditable = false
        view.isSelectable = false
        view.showsVerticalScrollIndicator = false
        return view
    }()

    private lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.text = BundleI18n.LarkContact.Lark_NewContacts_ShareMyLinkDescription_usedinLark
        return label
    }()

    private lazy var expireLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 1
        label.text = BundleI18n.LarkContact.Lark_Invitation_AddMembersExpiredTime
        return label
    }()
}
