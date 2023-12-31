//
//  MomentsChangeAccountButton.swift
//  Moment
//
//  Created by ByteDance on 2022/11/29.
//

import Foundation
import UIKit
import LarkBizAvatar
import AvatarComponent
import LarkNavigation
import UniverseDesignIcon
import LarkAccountInterface
import UniverseDesignBadge

class MomentsChangeAccountButton: UIButton, LarkNaviBarButtonDelegate {
    func larkNaviBarSetButtonTintColor(_ tintColor: UIColor, for state: UIControl.State) {
        if state == .normal {
            downIconView.tintColor = tintColor
        }
    }

    func larkNaviBarButtonWidth() -> CGFloat {
        return 40
    }

    let avatarWidth: CGFloat = 26

    var officialUser: MomentUser? {
        didSet {
            if let officialUser = officialUser {
                self.avatarView.setAvatarByIdentifier(officialUser.userID, avatarKey: officialUser.avatarKey)
            } else {
                guard let currentUser else { return }
                self.avatarView.setAvatarByIdentifier(currentUser.userID,
                                                      avatarKey: currentUser.avatarKey)
            }
        }
    }

    let currentUser: User?
    init(currentUser: User?) {
        self.currentUser = currentUser
        super.init(frame: .zero)
        setupSubview()
        badge = self.addBadge(.number, anchor: .topRight, anchorType: .rectangle)
    }

    func setupBadge(count: Int) -> UDBadge? {
        guard let badge = badge else {
            return nil
        }
        badge.config.number = count
        badge.isHidden = badge.config.number <= 0
        badge.config.maxNumber = MomentTab.maxBadgeCount
        badge.config.style = .characterBGRed
        badge.config.contentStyle = .custom(UIColor.ud.primaryOnPrimaryFill)
        return badge
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 头像
    public let avatarView = BizAvatar()

    /// 向下的小箭头图标
    public let downIconView = UIImageView()

    private func setupSubview() {
        addSubview(avatarView)

        self.avatarView.isUserInteractionEnabled = false
        self.avatarView.layer.masksToBounds = true
        self.avatarView.layer.cornerRadius = avatarWidth / 2
        self.addSubview(self.avatarView)
        self.avatarView.snp.makeConstraints { (make) in
            make.width.height.equalTo(avatarWidth)
            make.left.centerY.equalToSuperview()
        }

        addSubview(downIconView)
        downIconView.snp.makeConstraints { make in
            make.width.height.equalTo(10)
            make.right.centerY.equalToSuperview()
        }
        downIconView.image = UDIcon.downBoldScreenshotOutlined.withRenderingMode(.alwaysTemplate)
    }

}
