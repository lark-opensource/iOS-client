//
//  NaviBarAvatarView.swift
//  LarkFeed
//
//  Created by qihongye on 2018/12/26.
//

import UIKit
import Foundation
import LarkUIKit
import LarkTag
import SnapKit
import LarkBadge
import LarkAvatar
import UniverseDesignColor
import LarkBizAvatar
import UniverseDesignIcon

enum NaviBarAvatarViewBadge {
    case unknown
    case icon(UIImage)
    // 隐藏icon
    case iconNone
    // 显示红点
    case dot(DotType)
    // 隐藏红点
    case dotNone
}

struct NaviBarAvatarProps {
    var size: CGSize = CGSize(width: 36, height: 36)
    var badge: NaviBarAvatarViewBadge
    var badgeFontSize: UIFont?
    var badgeIcon: UIImage?
    var badgeTextColor: UIColor?
    var badgeSize: CGSize = CGSize(width: 17, height: 17)

    init(badge: NaviBarAvatarViewBadge = .unknown, badgeFontSize: UIFont? = nil, badgeIcon: UIImage? = nil, badgeTextColor: UIColor? = nil) {
        self.badge = badge
        self.badgeFontSize = badgeFontSize
        self.badgeIcon = badgeIcon
        self.badgeTextColor = badgeTextColor
    }
}

public final class LarkNaviAvatarView: UIView {
    lazy var avatarView: LarkMedalAvatar = {
        let imageView = LarkMedalAvatar(frame: .zero)
        return imageView
    }()

    private var hasBadgeNumberView = false
    lazy var badgeNumberView: BadgeView = {
        let badgeView = BadgeView(with: .label(.number(0)))

        self.addSubview(badgeView)
        // bdage中心点在头像圆坐标的正东北点上, x和y方向距离坐标轴r/sqrt(2), 即 直径 * 0.25 * sqrt(2)
        let centerOffset = self.avatarSize.height * CGFloat(0.25) * CGFloat(2.0).squareRoot()
        badgeView.snp.makeConstraints { (make) in
            make.centerX.equalTo(avatarView).offset(centerOffset)
            make.centerY.equalTo(avatarView).offset(-centerOffset)
        }
        hasBadgeNumberView = true
        return badgeView
    }()

    private var hasBadgeIcon = false
    lazy var badgeIcon: UIImageView = { () -> UIImageView in
        let iconView = UIImageView()
        iconView.snp.makeConstraints { (make) in
            make.width.equalTo(props.badgeSize.width)
            make.height.equalTo(props.badgeSize.height)
        }
        iconView.layer.cornerRadius = props.badgeSize.height / 2
        iconView.layer.masksToBounds = true

        self.addSubview(iconView)
        iconView.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(-10)
            make.top.equalTo(avatarView.snp.top).offset(-(props.badgeSize.height - 10))
        }

        hasBadgeIcon = true
        return iconView
    }()

    var avatarSize: CGSize

    var isNeedShowBadgeIcon: Bool = false {
        didSet {
            self.updateBadgeIcon()
        }
    }

    /// 设置badge属性
    var props: NaviBarAvatarProps {
        didSet {
            self.updateBadgeIcon()
        }
    }

    private var leanModeStatus: Bool = false

    init(props: NaviBarAvatarProps = NaviBarAvatarProps()) {
        self.props = props
        self.avatarSize = self.props.size
        super.init(frame: .zero)
        /// 添加头像
        self.addSubview(self.avatarView)
        layoutViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setAvatarSize(size: CGSize) {
        let cornerRadius = size.height / 2
        avatarView.layer.cornerRadius = cornerRadius
        avatarView.border.layer.cornerRadius = cornerRadius
        self.avatarSize = size
    }

    func resetAvatarSize() {
        avatarView.layer.cornerRadius = self.props.size.height / 2
        avatarView.border.layer.cornerRadius = self.props.size.height / 2
        self.avatarSize = self.props.size
    }

    private func layoutViews() {
        let cornerRadius = self.avatarSize.height / 2
        avatarView.layer.cornerRadius = cornerRadius
        avatarView.border.layer.cornerRadius = cornerRadius
        avatarView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private var wantDisplayIcon = false

    /// 统一处理badge的展示逻辑，优先级： badge > icon
    private func updateBadgeIcon() {
        switch props.badge {
        case .icon(let icon):
            self.badgeIcon.image = icon
            // 如果红点已经展示, 则不显示icon
            if hasBadgeNumberView, !self.badgeNumberView.isHidden {
                self.badgeIcon.isHidden = true
                wantDisplayIcon = true
                return
            }
            self.badgeIcon.isHidden = false
        // 取消icon
        case .iconNone:
            wantDisplayIcon = false
            if hasBadgeIcon {
                self.badgeIcon.isHidden = true
            }
        // 红点
        case .dot(let dotType):
            guard isNeedShowBadgeIcon else { break }
            // show red Dot view
            self.badgeNumberView.type = .dot(dotType)
            self.badgeNumberView.isHidden = false
            // 显示红点的时候隐藏icon
            if hasBadgeNumberView, !self.badgeNumberView.isHidden {
                self.badgeIcon.isHidden = true
                wantDisplayIcon = true
            }
        // 取消红点
        case .dotNone:
            if hasBadgeNumberView {
                self.badgeNumberView.isHidden = true
            }
            if hasBadgeIcon, wantDisplayIcon, let _ = self.badgeIcon.image {
                wantDisplayIcon = false
                self.badgeIcon.isHidden = false
            }
        case .unknown:
            break
        }
    }

    func setAvatar(entityId: String, avatarKey: String, medalKey: String) {
        avatarView.setAvatarByIdentifier(entityId,
                                           avatarKey: avatarKey,
                                           medalKey: medalKey,
                                           medalFsUnit: "",
                                                   scene: .Chat,
                                         avatarViewParams: .init(sizeType: .size(avatarSize.width)),
                                           backgroundColorWhenError: UIColor.ud.textPlaceholder)
        self.setLeanModeStatus(status: self.leanModeStatus)
    }

    func setLeanModeStatus(status: Bool) {
        self.leanModeStatus = status
        // 根据精简模式状态再设置下border，避免因为勋章把border给冲掉了
        if status {
            avatarView.updateBorderColorAndWidth(UIColor.ud.primaryContentDefault, 2)
            avatarView.insertSubview(avatarView.border, aboveSubview: avatarView.avatar)
        } else {
            avatarView.updateBorderColorAndWidth(nil, 0)
            avatarView.insertSubview(avatarView.border, belowSubview: avatarView.avatar)
        }
    }
}
