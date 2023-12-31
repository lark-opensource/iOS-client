//
//  QRCodeCardView.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/10/29.
//

import UIKit
import Foundation
import LarkUIKit
import LarkLocalizations
import SnapKit
import QRCode
import RxSwift
import Homeric
import ByteWebImage
import UniverseDesignColor
import UniverseDesignTheme
import UniverseDesignShadow
import LarkBizAvatar
import LarkAccountInterface
import LarkContainer
import EENavigator

final class QRCodeCardView: UIView, CardBindable, CardRefreshable {

    var isAdmin: Bool = false {
        didSet {
            if isAdmin {
                container.tipText = BundleI18n.LarkContact.Lark_AdminUpdate_Toast_MobileOrgQRCodeAdmin
            } else {
                container.tipText = BundleI18n.LarkContact.Lark_AdminUpdate_Toast_MobileOrgQRCodeContactAdmin
            }
        }
    }

    private weak var delegate: (UIViewController & CardInteractiable)?
    private let inviteMonitor = InviteMonitor()
    private var isOversea: Bool
    let navigator: Navigatable

    init(isOversea: Bool, delegate: (UIViewController & CardInteractiable)?, navigator: Navigatable) {
        self.isOversea = isOversea
        self.delegate = delegate
        self.navigator = navigator
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .ud.bgBody

        if isOversea {
            container.tipLabel.text = BundleI18n.LarkContact.Lark_AdminUpdate_Subtitle_MobileInviteBelowOrg
            container.infoButton.isHidden = true
        } else {
            container.tipLabel.text = BundleI18n.LarkContact.Lark_AdminUpdate_PH_MobileOrgQRCode
        }
        container.onResetBlock = { [weak self] in
            self?.delegate?.triggleRefreshAction(cardType: .qrcode)
        }
        addSubview(container)
        container.snp.makeConstraints { make in
            make.top.equalTo(36)
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.height.greaterThanOrEqualTo(380)
        }

        qrCodeView.addSubview(teamLogoView)
        teamLogoView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 24, height: 24))
            make.center.equalToSuperview()
        }

        qrCodeWrapper.addSubview(qrCodeView)
        qrCodeView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 132, height: 132))
            make.center.equalToSuperview()
        }

        container.addSubview(qrCodeWrapper)
        qrCodeWrapper.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 148, height: 148))
            make.centerX.equalToSuperview()
            make.top.equalTo(136)
        }

    }

    func bindWithModel(cardInfo: InviteAggregationInfo) {
        container.tenantLabel.text = cardInfo.tenantName

        let startTimeInterval = CACurrentMediaTime()
        inviteMonitor.startEvent(
            name: Homeric.UG_INVITE_MEMBER_NONDIRECTIONAL_LOAD_QRCODE,
            indentify: String(startTimeInterval),
            reciableEvent: .memberOrientationLoadQrcode
        )
        if let memberInviteInfo = cardInfo.memberExtraInfo {
            if let qrcodeImage = QRCodeTool.createQRImg(str: memberInviteInfo.urlForQRCode, size: UIScreen.main.bounds.size.width) {
                inviteMonitor.endEvent(
                    name: Homeric.UG_INVITE_MEMBER_NONDIRECTIONAL_LOAD_QRCODE,
                    indentify: String(startTimeInterval),
                    category: ["succeed": "true"],
                    reciableState: .success,
                    needNet: false,
                    reciableEvent: .memberOrientationLoadQrcode
                )
                qrCodeWrapper.backgroundColor = UIColor.ud.primaryOnPrimaryFill
                qrCodeView.image = qrcodeImage
            } else {
                inviteMonitor.endEvent(
                    name: Homeric.UG_INVITE_MEMBER_NONDIRECTIONAL_LOAD_QRCODE,
                    indentify: String(startTimeInterval),
                    category: ["succeed": "false"],
                    reciableState: .failed,
                    needNet: false,
                    reciableEvent: .memberOrientationLoadQrcode
                )
            }
            teamLogoView.bt.setLarkImage(with: .default(key: memberInviteInfo.teamLogoURL),
                                         completion: { [weak self] result in
                                            if (try? result.get().image) != nil {
                                                self?.teamLogoView.isHidden = false
                                            }
                                         })
            container.expireLabel.text = BundleI18n.LarkContact.Lark_AdminUpdate_Subtitle_MobileQRCodeExpire(memberInviteInfo.expireDateDesc)
        }
    }

    func setRefreshing(_ toRefresh: Bool) {
        container.setRefreshing(toRefresh)
    }

    private lazy var container = InviteContainerView(hostViewController: delegate, navigator: navigator)

    private lazy var qrCodeWrapper: UIView = {
        let view = UIView()
        view.layer.cornerRadius = IGLayer.commonPopPanelRadius
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var qrCodeView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 4.0
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var teamLogoView: UIImageView = {
        let view = UIImageView()
        view.layer.borderWidth = 1.0
        view.layer.ud.setBorderColor(UIColor.ud.primaryOnPrimaryFill)

        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()

    func setContainerAuroraEffect(isDarkModeTheme: Bool) {
        container.setAuroraEffect(isDarkModeTheme: isDarkModeTheme)
    }
}
