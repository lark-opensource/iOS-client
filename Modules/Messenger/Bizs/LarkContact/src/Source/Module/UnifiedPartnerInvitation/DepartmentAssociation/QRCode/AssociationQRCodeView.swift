//
//  AssociationQRCodeView.swift
//  LarkContact
//
//  Created by shizhengyu on 2021/3/29.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignColor
import LarkLocalizations
import SnapKit
import QRCode
import RxSwift
import Homeric
import LarkSDKInterface
import ByteWebImage
import LarkMessengerInterface
import UniverseDesignTheme

final class AssociationQRCodeView: UIView, CardRefreshable {
    private weak var delegate: CardInteractiable?
    private let inviteMonitor = InviteMonitor()
    private let disposeBag = DisposeBag()
    private let avatarSize: CGFloat = 40

    init(gapScale: CGFloat,
         delegate: CardInteractiable? = nil) {
        self.delegate = delegate
        super.init(frame: .zero)
        backgroundColor = UIColor.clear
        layoutPageSubviews(gapScale: gapScale)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindWithModel(cardInfo: AssociationInviteInfo) {
        let tenantAvatarKey = cardInfo.meta.tenantAvatar.key
        if let qrcodeImage = QRCodeTool.createQRImg(str: cardInfo.meta.url, size: UIScreen.main.bounds.size.width) {
            qrcodeView.image = qrcodeImage
            bgQRCodeView.backgroundColor = UIColor.ud.primaryOnPrimaryFill & UIColor.ud.N900
        }
        teamLogoView.bt.setLarkImage(with: .avatar(key: tenantAvatarKey,
                                                   entityID: "",
                                                   params: .init(sizeType: .size(avatarSize))),
                                     trackStart: {
                                       return TrackInfo(scene: .Contact, fromType: .avatar)
                                     },
                                     completion: { [weak self] result in
                                        if case .failure = result {
                                            self?.teamLogoView.isHidden = true
                                        }

        })
        expireLabel.text = "\(BundleI18n.LarkContact.Lark_Invitation_AddMembersExpiredTime)\(cardInfo.expireDateDesc)"
    }

    func setRefreshing(_ toRefresh: Bool) {
        refreshWrapper.isEnabled = !toRefresh
    }

    func updateTipWithIsOversea(_ isOversea: Bool) {
        let text = isOversea ? BundleI18n.LarkContact.Lark_B2B_SuperScanCodeLark() : BundleI18n.LarkContact.Lark_B2B_SuperScanCode()
        tipLabel.setText(text: text, lineSpacing: 4)
    }

    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.layer.cornerRadius = 8.0
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1.0
        view.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        return view
    }()

    private lazy var contentWrapper: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()

    private lazy var gradientBackgroundView: UIView = {
        let view = AssociationQRCodeBackgroundView()
        return view
    }()

    private lazy var bgQRCodeView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var qrcodeView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        return view
    }()

    private lazy var teamLogoView: UIImageView = {
        let view = UIImageView()
        view.layer.borderWidth = 1.0
        view.layer.ud.setBorderColor(UIColor.ud.N00)
        view.layer.cornerRadius = 1.5
        view.layer.masksToBounds = true
        view.isHidden = false
        return view
    }()

    private lazy var refreshArea: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var tipLabel: InsetsLabel = {
        let label = InsetsLabel(frame: .zero, insets: .zero)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.numberOfLines = 0
        label.setText(
            text: BundleI18n.LarkContact.Lark_TrustedOrg_Descrip_BotNotificationOnceRequestSubmitted,
            lineSpacing: 4
        )
        return label
    }()

    private lazy var expireLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 1
        label.text = BundleI18n.LarkContact.Lark_B2B_ExpiresBy
        return label
    }()

    private lazy var refreshWrapper: UIButton = {
        let wrapper = UIButton(type: .custom)
        wrapper.backgroundColor = .clear
        wrapper.setTitle(BundleI18n.LarkContact.Lark_B2B_Reset2, for: .normal)
        wrapper.setTitleColor(.ud.colorfulBlue, for: .normal)
        wrapper.titleLabel?.font = .systemFont(ofSize: 12)
        wrapper.addTarget(self, action: #selector(handleRefresh), for: .touchUpInside)
        return wrapper
    }()

    @objc
    func handleRefresh() {
        self.delegate?.triggleRefreshAction(cardType: .qrcode)
    }

    private lazy var operationPanel: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N00
        return view
    }()
}

private extension AssociationQRCodeView {
    private func layoutPageSubviews(gapScale: CGFloat) {
        addSubview(contentWrapper)
        contentWrapper.addSubview(contentView)
        contentView.addSubview(gradientBackgroundView)
        contentView.addSubview(bgQRCodeView)
        contentView.addSubview(qrcodeView)
        qrcodeView.addSubview(teamLogoView)
        contentView.addSubview(tipLabel)
        contentView.addSubview(refreshArea)
        refreshArea.addSubview(expireLabel)
        refreshArea.addSubview(refreshWrapper)

        contentWrapper.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        gradientBackgroundView.snp.makeConstraints { ( make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(gradientBackgroundView.snp.width).multipliedBy(890.0 / 666)
        }
        bgQRCodeView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(62)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(148)
        }
        qrcodeView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(72)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(128)
        }
        teamLogoView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(24)
        }
        refreshArea.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.height.equalTo(20)
            make.top.equalTo(bgQRCodeView.snp.bottom).offset(24)
        }
        expireLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        refreshWrapper.snp.makeConstraints { (make) in
            make.left.equalTo(expireLabel.snp.right).offset(20)
            make.right.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
        tipLabel.snp.makeConstraints { make in
            make.top.equalTo(refreshArea.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
        }

    }
}

final class AssociationQRCodeBackgroundView: UIView {
    private lazy var topGradientMainCircle = GradientCircleView()
    private lazy var topGradientSubCircle = GradientCircleView()
    private lazy var topGradientRefCircle = GradientCircleView()
    private lazy var blurEffectView = UIVisualEffectView()

    init() {
        super.init(frame: .zero)
        addSubview(topGradientMainCircle)
        addSubview(topGradientSubCircle)
        addSubview(topGradientRefCircle)
        topGradientMainCircle.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(106.0)
            make.top.equalToSuperview().offset(-46.0)
            make.width.equalToSuperview().multipliedBy(144.0 / 336)
            make.height.equalToSuperview().multipliedBy(116.0 / 380)
        }
        topGradientSubCircle.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(-70.0)
            make.top.equalToSuperview().offset(-136.0)
            make.width.equalToSuperview().multipliedBy(244.0 / 336)
            make.height.equalToSuperview().multipliedBy(202.0 / 380)
        }
        topGradientRefCircle.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(174)
            make.top.equalToSuperview().offset(-89)
            make.width.equalToSuperview().multipliedBy(212.0 / 336)
            make.height.equalToSuperview().multipliedBy(151.0 / 380)
        }

        var isDarkModeTheme: Bool = false
        if #available(iOS 13.0, *) {
            isDarkModeTheme = UDThemeManager.getRealUserInterfaceStyle() == .dark
        }

        addSubview(blurEffectView)
        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        setAuroraEffect(isDarkModeTheme: isDarkModeTheme)
    }

    func setAuroraEffect(isDarkModeTheme: Bool) {
        if isDarkModeTheme {
            topGradientMainCircle.setColors(color: UIColor.ud.rgb("#75A4FF"), opacity: 0.2)
            topGradientSubCircle.setColors(color: UIColor.ud.rgb("#4C88FF"), opacity: 0.25)
            topGradientRefCircle.setColors(color: UIColor.ud.rgb("#135A78"), opacity: 0.2)
            blurEffectView.effect = UIBlurEffect(style: .dark)
        } else {
            topGradientMainCircle.setColors(color: UIColor.ud.rgb("#1456F0"), opacity: 0.2)
            topGradientSubCircle.setColors(color: UIColor.ud.rgb("#336DF4"), opacity: 0.25)
            topGradientRefCircle.setColors(color: UIColor.ud.rgb("#3EC3F7"), opacity: 0.2)
            blurEffectView.effect = UIBlurEffect(style: .light)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #available(iOS 13.0, *),
            traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
            return
        }
        setAuroraEffect(isDarkModeTheme: UDThemeManager.getRealUserInterfaceStyle() == .dark)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
