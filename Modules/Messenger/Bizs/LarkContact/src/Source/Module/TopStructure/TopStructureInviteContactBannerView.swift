//
//  TopStructureInviteContactBannerView.swift
//  LarkContact
//
//  Created by ByteDance on 2022/9/27.
//

import UIKit
import Foundation
import EENavigator
import LarkUIKit
import UniverseDesignIcon
import LKCommonsTracker
import Homeric
import LarkContainer

final class TopStructureInviteContactBannerView: UIView {

    final class Layout {
        static var hPadding: CGFloat = 16
        static var vPadding: CGFloat = 12
        static var iconSize: CGFloat = 16
        static var moduleSpacing: CGFloat = 8
        static var buttonInsets: UIEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    }

    public func getBannerHeight(width: CGFloat) -> CGFloat {
        let maxSize = CGFloat.greatestFiniteMagnitude
        let buttonWidth = inviteBtn.titleLabel?.sizeThatFits(CGSize(width: maxSize, height: maxSize)).width ?? 0 + Layout.buttonInsets.left * 2
        let titleWidth = width - buttonWidth - Layout.hPadding * 2 - Layout.iconSize - Layout.moduleSpacing * 2
        let totalHeight = titleLabel.sizeThatFits(CGSize(width: titleWidth, height: maxSize)).height + Layout.vPadding * 2
        return max(totalHeight, 44)
    }

    var icon = UIImageView()
    var titleLabel = UILabel()
    var inviteBtn = UIButton(type: .custom)
    var applink = ""
    private let userResolver: UserResolver

    init(title: String = "", btnText: String = "", applink: String = "", resolver: UserResolver) {
        self.userResolver = resolver
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.functionInfoFillSolid02
        icon.image = UDIcon.getIconByKey(.teamAddOutlined, iconColor: UIColor.ud.colorfulBlue)
        titleLabel.numberOfLines = 2
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        titleLabel.textColor = UIColor.ud.B900
        let pureImage = UIImage.ud.fromPureColor(UIColor.ud.primaryContentDefault)
        inviteBtn.setBackgroundImage(pureImage, for: .normal)
        inviteBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        inviteBtn.titleLabel?.textColor = UIColor.ud.primaryOnPrimaryFill
        inviteBtn.contentEdgeInsets = Layout.buttonInsets
        inviteBtn.layer.cornerRadius = 6
        inviteBtn.clipsToBounds = true
        inviteBtn.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        addSubview(icon)
        addSubview(titleLabel)
        addSubview(inviteBtn)
        icon.snp.makeConstraints { make in
            make.left.equalTo(Layout.hPadding)
            make.height.width.equalTo(Layout.iconSize)
            make.top.equalTo(14)
        }
        inviteBtn.snp.makeConstraints { make in
            make.right.equalTo(-Layout.hPadding)
            make.height.equalTo(28)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(Layout.moduleSpacing)
            make.centerY.equalToSuperview()
            make.right.equalTo(inviteBtn.snp.left).offset(-Layout.moduleSpacing)
        }
        inviteBtn.addTarget(self, action: #selector(inviteBtnDidClick), for: .touchUpInside)
        updateContent(title: title, btnText: btnText, applink: applink)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateContent(title: String, btnText: String, applink: String) {
        titleLabel.text = title
        self.applink = applink
        inviteBtn.setTitle(btnText, for: .normal)
    }

    @objc
    func inviteBtnDidClick() {
        guard let window = userResolver.navigator.mainSceneWindow,
              let applink = URL(string: applink) else {
            return
        }
        Tracker.post(TeaEvent(Homeric.CONTACT_ADDMEMBER_CARD_CLICK, params: ["click": "invite_now", "target": "none"]))
        userResolver.navigator.present(applink, wrap: LkNavigationController.self, from: window)
    }
}
