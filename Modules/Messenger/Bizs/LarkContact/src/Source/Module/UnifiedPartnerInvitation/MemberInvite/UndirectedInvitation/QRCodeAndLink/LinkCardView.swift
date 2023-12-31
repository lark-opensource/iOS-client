//
//  LinkCardView.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/10/30.
//

import UIKit
import Foundation
import LarkUIKit
import LarkLocalizations
import SnapKit
import QRCode
import RxSwift
import UniverseDesignColor
import LarkIllustrationResource
import LarkNavigator
import EENavigator

final class LinkCardView: UIView, CardBindable, CardRefreshable {

    var isAdmin: Bool = false {
        didSet {
            if isAdmin {
                container.tipText = BundleI18n.LarkContact.Lark_AdminUpdate_Toast_MobileOrgLinkAdmin
            } else {
                container.tipText = BundleI18n.LarkContact.Lark_AdminUpdate_Toast_MobileOrgLinkContactAdmin
            }
        }
    }

    private weak var delegate: (UIViewController & CardInteractiable)?
    private let disposeBag = DisposeBag()

    private lazy var linkView: UITextView = {
        let view = UITextView(frame: .zero)
        view.textContainerInset = UIEdgeInsets(top: 16, left: 14, bottom: 16, right: 14)
        view.backgroundColor = .ud.bgFloatOverlay
        view.textColor = .ud.N900
        view.font = .ud.body2
        view.textAlignment = .left
        view.layer.cornerRadius = IGLayer.commonPopPanelRadius
        view.layer.masksToBounds = true
        view.isEditable = false
        view.isSelectable = false
        view.showsVerticalScrollIndicator = false
        return view
    }()

    private lazy var container = InviteContainerView(hostViewController: delegate, navigator: navigator)
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
            self?.delegate?.triggleRefreshAction(cardType: .link)
        }
        addSubview(container)
        container.snp.makeConstraints { make in
            make.top.equalTo(36)
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.height.greaterThanOrEqualTo(380)
        }

        container.addSubview(linkView)
        linkView.snp.makeConstraints { (make) in
            make.top.equalTo(136)
            make.left.right.equalToSuperview().inset(20)
            make.height.greaterThanOrEqualTo(148)
        }

    }

    func bindWithModel(cardInfo: InviteAggregationInfo) {
        container.tenantLabel.text = cardInfo.tenantName
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        // 根据 https://bytedance.feishu.cn/docx/VpZTdl1IioCrENxfWakcPcrwnFo 替换为 byWordWrapping
        paragraphStyle.lineBreakMode = .byWordWrapping

        if let memberInviteInfo = cardInfo.memberExtraInfo {
            let inviteMsg: String
            if isOversea {
                inviteMsg = BundleI18n.LarkContact.Lark_Invitation_FeishuCopyToken(
                    cardInfo.tenantName,
                    memberInviteInfo.urlForLink,
                    memberInviteInfo.teamCode.replacingOccurrences(of: " ", with: "")
                )
            } else {
                inviteMsg = BundleI18n.LarkContact.Lark_AdminUpdate_Link_MobileJoinOrgContactAdminDetail(
                    cardInfo.tenantName,
                    memberInviteInfo.urlForLink,
                    memberInviteInfo.teamCode.replacingOccurrences(of: " ", with: "")
                )
            }
            linkView.attributedText = NSAttributedString(
                string: inviteMsg,
                attributes: [.paragraphStyle: paragraphStyle,
                             .font: UIFont.ud.body2,
                             .foregroundColor: UIColor.ud.N900]
            )
            container.expireLabel.text = BundleI18n.LarkContact.Lark_AdminUpdate_Subtitle_MobileLinkExpire(memberInviteInfo.expireDateDesc)
        }
    }

    func setRefreshing(_ toRefresh: Bool) {
        container.setRefreshing(toRefresh)
    }

    func setContainerAuroraEffect(isDarkModeTheme: Bool) {
        container.setAuroraEffect(isDarkModeTheme: isDarkModeTheme)
    }
}
