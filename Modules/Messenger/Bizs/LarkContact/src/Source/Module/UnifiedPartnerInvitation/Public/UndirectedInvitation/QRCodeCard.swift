//
//  QRCodeCard.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/12/15.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import QRCode
import LKMetric
import Homeric
import ByteWebImage
import UniverseDesignColor
import LarkBizAvatar
import LarkAccountInterface
import LarkContainer

final class QRCodeCard: UIView, CardBindable {
    let scenes: UnifiedNoDirectionalScenes
    var switchToLinkHandler: (() -> Void)?
    private let monitor = InviteMonitor()
    private let userResolver: UserResolver
    let disposeBag = DisposeBag()

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

        let startTimeInterval = CACurrentMediaTime()
        var qrlinkGenUrl: String?
        switch scenes {
        case .parent:
            qrlinkGenUrl = cardInfo.parentExtraInfo?.inviteQrURL
            monitor.startEvent(
                name: Homeric.UG_INVITE_PARENT_NONDIRECTIONAL_LOAD_QRCODE,
                indentify: String(startTimeInterval),
                reciableEvent: .parentOrientationLoadQrcode
            )
        case .external:
            qrlinkGenUrl = cardInfo.externalExtraInfo?.qrcodeInviteData.inviteURL
            monitor.startEvent(
                name: Homeric.UG_INVITE_EXTERNAL_NONDIRECTIONAL_LOAD_QRCODE,
                indentify: String(startTimeInterval),
                reciableEvent: .externalOrientationLoadQrcode
            )
        }
        if let qrlinkGenUrl = qrlinkGenUrl,
            let qrcodeImage = QRCodeTool.createQRImg(str: qrlinkGenUrl, size: UIScreen.main.bounds.size.width) {
            qrcodeView.image = qrcodeImage
            switch scenes {
            case .external:
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
            case .parent:
                monitor.endEvent(
                    name: Homeric.UG_INVITE_PARENT_NONDIRECTIONAL_LOAD_QRCODE,
                    indentify: String(startTimeInterval),
                    category: ["succeed": "true"],
                    extra: [:],
                    reciableState: .success,
                    needNet: false,
                    reciableEvent: .parentOrientationLoadQrcode
                )
            }
        } else {
            switch scenes {
            case .external:
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
            case .parent:
                monitor.endEvent(
                    name: Homeric.UG_INVITE_PARENT_NONDIRECTIONAL_LOAD_QRCODE,
                    indentify: String(startTimeInterval),
                    category: ["succeed": "false"],
                    extra: [:],
                    reciableState: .failed,
                    needNet: false,
                    reciableEvent: .parentOrientationLoadQrcode
                )
            }
        }
        if scenes == .parent {
            expireLabel.text = "\(BundleI18n.LarkContact.Lark_Invitation_AddMembersExpiredTime)\(cardInfo.parentExtraInfo?.expireDateDesc ?? "")"
        }
    }

    private func layoutPageSubviews() {
        addSubview(avatarView)
        addSubview(infoView)
        infoView.addSubview(nameLabel)
        infoView.addSubview(companyLabel)
        addSubview(switchToLinkView)
        addSubview(contentWrapper)
        contentWrapper.addSubview(bgQRCodeView)
        contentWrapper.addSubview(qrcodeView)
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
        switchToLinkView.snp.makeConstraints { (make) in
            make.top.trailing.equalToSuperview()
            make.width.height.equalTo(60)
        }
        switch scenes {
        case .parent:
            contentWrapper.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(avatarView.snp.bottom).offset(42)
                make.height.equalTo(240)
            }
            bgQRCodeView.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(0)
                make.centerX.equalToSuperview()
                make.width.height.equalTo(170)
            }
            qrcodeView.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(10)
                make.centerX.equalToSuperview()
                make.width.height.equalTo(150)
            }
            expireLabel.snp.makeConstraints { (make) in
                make.top.equalTo(qrcodeView.snp.bottom).offset(12)
                make.centerX.equalToSuperview()
            }
        case .external:
            contentWrapper.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(avatarView.snp.bottom).offset(60)
                make.height.equalTo(300)
            }
            bgQRCodeView.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(0)
                make.centerX.equalToSuperview()
                make.width.height.equalTo(240)
            }
            qrcodeView.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(10)
                make.centerX.equalToSuperview()
                make.width.height.equalTo(220)
            }
            tipLabel.snp.makeConstraints { (make) in
                make.top.equalTo(qrcodeView.snp.bottom).offset(12)
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

    private lazy var switchToLinkView: UIImageView = {
        let view = UIImageView()
        view.image = Resources.switch_to_link
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer()
        tap.rx.event.asDriver().drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.switchToLinkHandler?()
        }).disposed(by: disposeBag)
        view.addGestureRecognizer(tap)
        return view
    }()

    private lazy var contentWrapper: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var bgQRCodeView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.primaryOnPrimaryFill & UIColor.ud.N900
        return view
    }()

    private lazy var qrcodeView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        return view
    }()

    private lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.text = BundleI18n.LarkContact.Lark_NewContacts_ShareMyQrCodeDescription
        label.isHidden = (scenes == .parent)
        return label
    }()

    private lazy var expireLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 1
        label.text = BundleI18n.LarkContact.Lark_Invitation_AddMembersExpiredTime
        return label
    }()
}
