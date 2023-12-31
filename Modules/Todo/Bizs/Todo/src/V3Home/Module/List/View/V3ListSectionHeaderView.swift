//
//  V3ListSectionHeaderView.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/22.
//

import Foundation
import UniverseDesignIcon
import UIKit
import LarkBizAvatar

// MARK: - Section Header

final class V3ListSectionHeaderView: UICollectionReusableView {

    var viewData: V3ListSectionHeaderData? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            isHidden = false
            if viewData.isFoldHidden {
                leadingIconView.isHidden = true
            } else {
                leadingIconView.isHidden = false
                leadingIconView.transform = viewData.isFold ? CGAffineTransform.identity.rotated(by: -.pi / 2) : .identity
            }

            if let titleInfo = viewData.titleInfo {
                if let icon = titleInfo.icon {
                    titleIconView.isHidden = false
                    titleIconView.image = icon
                } else {
                    titleIconView.isHidden = true
                }
                titleLabel.isHidden = false
                titleLabel.text = titleInfo.text
            } else {
                titleLabel.isHidden = true
                titleIconView.isHidden = true
            }

            if let user = viewData.singleUser {
                singleUserView.isHidden = false
                singleUserView.viewData = .init(avatar: user.avatar, name: user.name, nameWidth: viewData.layoutInfo?.userWidth ?? 0)
            } else {
                singleUserView.isHidden = true
            }

            if let users = viewData.multiUsers {
                multiUsersView.isHidden = false
                multiUserContainerView.isHidden = false
                multiUsersView.viewData = users
            } else {
                multiUserContainerView.isHidden = true
                multiUsersView.isHidden = true
            }

            if let badgeCount = viewData.badgeCount, badgeCount > 0 {
                badgeLabel.isHidden = false
                badgeLabel.text = badgeCount > 1_000 ? "999+" : "\(badgeCount)"
            } else {
                badgeLabel.isHidden = true
            }

            if let totalCount = viewData.totalCount, totalCount > 0 {
                if let badgeCount = viewData.badgeCount, badgeCount == totalCount {
                    countLabel.isHidden = true
                } else {
                    countLabel.isHidden = false
                    countLabel.text = "\(totalCount)"
                }
            } else {
                countLabel.isHidden = true
            }

            trailingIconView.isHidden = !viewData.hasMore
            setNeedsLayout()
        }
    }

    /// 分割线
    var showSeparateLine: Bool = true {
        didSet {
            separateLine.isHidden = !showSeparateLine
        }
    }

    var tapSectionHandler: (() -> Void)?
    var tapMoreHandler: (() -> Void)?

    private lazy var leadingIconView: UIImageView = {
        let imageView = UIImageView(
            image: UDIcon.getIconByKey(.expandDownFilled, iconColor: UIColor.ud.iconN2, size: ListConfig.Section.leadingIconSize)
        )
        return imageView
    }()

    // 主要显示来源icon
    private lazy var titleIconView = UIImageView()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = ListConfig.Section.titleFont
        label.numberOfLines = 1
        return label
    }()

    private lazy var multiUsersView = AvatarGroupView(style: .normal)
    private lazy var multiUserContainerView: UIView = {
        let view = UIView()
        view.addSubview(multiUsersView)
        view.backgroundColor = UIColor.ud.bgBodyOverlay
        view.layer.cornerRadius = ListConfig.Section.contentHeight / 2
        view.layer.masksToBounds = true
        return view
    }()
    private lazy var singleUserView = V3ListSingleUserView()

    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = ListConfig.Section.mainFont
        label.textAlignment = .center
        label.backgroundColor = ListConfig.Cell.bgColor
        label.layer.masksToBounds = true
        label.isHidden = true
        return label
    }()

    private lazy var badgeLabel: UILabel = {
        let label = UILabel()
        label.font = ListConfig.Section.badgeFont
        label.textAlignment = .center
        label.backgroundColor = UIColor.ud.functionDangerContentDefault
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.isHidden = true
        return label
    }()

    private lazy var trailingIconView: UIButton = {
        let button = UIButton()
        button.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -10, bottom: -8, right: -10)
        button.addTarget(self, action: #selector(clickMore), for: .touchUpInside)
        let image = UDIcon.getIconByKey(
            .moreOutlined,
            iconColor: UIColor.ud.iconN2,
            size: CGSize(width: 20, height: 20)
        )
        button.setImage(image, for: .normal)
        return button
    }()
    private lazy var separateLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    private(set) lazy var containerView: UIView = {
        let view = UIView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickSectionHeader))
        view.addGestureRecognizer(tap)
        view.backgroundColor = ListConfig.Cell.bgColor
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(containerView)

        containerView.addSubview(leadingIconView)
        containerView.addSubview(titleIconView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(multiUserContainerView)
        containerView.addSubview(singleUserView)
        containerView.addSubview(badgeLabel)
        containerView.addSubview(countLabel)
        containerView.addSubview(trailingIconView)
        containerView.addSubview(separateLine)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let viewData = viewData else { return }
        containerView.frame = CGRect(
            x: ListConfig.Cell.leftPadding,
            y: 0,
            width: bounds.width - ListConfig.Cell.leftPadding - ListConfig.Cell.rightPadding,
            height: bounds.height
        )
        typealias Config = ListConfig.Section

        var offsetX: CGFloat = Config.horizontalPadding
        if !leadingIconView.isHidden {
            leadingIconView.frame = CGRect(
                x: offsetX,
                y: (bounds.height - Config.leadingIconSize.height) / 2,
                width: Config.leadingIconSize.width,
                height: Config.leadingIconSize.height
            )
            offsetX = leadingIconView.frame.maxX + Config.horizontalSpace
        }
        if !titleIconView.isHidden {
            titleIconView.frame = CGRect(
                x: offsetX,
                y: (frame.height - Config.titleIconSize.height) / 2,
                width: Config.titleIconSize.width,
                height: Config.titleIconSize.height
            )
            offsetX += Config.titleIconSize.width + Config.titleIconSpace
        }

        // 计算title 宽度
        var titleWidth = bounds.width - offsetX - Config.horizontalPadding - ListConfig.Cell.leftPadding - ListConfig.Cell.rightPadding
        if !trailingIconView.isHidden {
            titleWidth -= Config.trailingIconSize.width + Config.rHorizontalSpace
        }
        if !countLabel.isHidden {
            titleWidth -= Config.horizontalSpace + (viewData.layoutInfo?.totalCntWidth ?? 0)
        }
        let badgeWidth: CGFloat = 16.0
        if !badgeLabel.isHidden, let badgeCount = viewData.badgeCount {
            var badgeWidth: CGFloat = 16.0
            if badgeCount < 10 {
                badgeWidth = 16.0
            } else if badgeCount > 10, badgeCount < 99 {
                badgeWidth = 24.0
            } else if badgeCount > 99, badgeCount < 999 {
                badgeWidth = 32.0
            } else {
                badgeWidth = viewData.layoutInfo?.badgeWidth ?? 0 + Config.horizontalSpace
            }
            titleWidth -= Config.horizontalSpace + badgeWidth
        }

        let contentY = (frame.height - Config.contentHeight) / 2
        if !titleLabel.isHidden {
            titleLabel.frame = CGRect(
                x: offsetX,
                y: contentY,
                width: min(viewData.layoutInfo?.titleWidth ?? 0, titleWidth),
                height: Config.contentHeight
            )
            offsetX += titleLabel.frame.width
        }

        if !singleUserView.isHidden {
            singleUserView.frame = CGRect(
                x: offsetX,
                y: contentY,
                width: min(viewData.layoutInfo?.userWidth ?? 0, titleWidth),
                height: Config.contentHeight
            )
            // 和title是互斥的
            offsetX += singleUserView.frame.width
        }

        if !multiUserContainerView.isHidden {
            multiUserContainerView.frame = CGRect(
                x: offsetX,
                y: contentY,
                width: (viewData.multiUsers?.width ?? 0) + 4,
                height: Config.contentHeight
            )
            multiUsersView.frame = CGRect(
                x: 2,
                y: 2,
                width: viewData.multiUsers?.width ?? 0,
                height: CheckedAvatarView.Style.normal.height
            )
            // 和title, single是互斥的
            offsetX += multiUserContainerView.frame.width
        }

        /// total count frame
        if !countLabel.isHidden {
            countLabel.frame = CGRect(
                x: offsetX + Config.horizontalSpace,
                y: contentY,
                width: viewData.layoutInfo?.totalCntWidth ?? 0,
                height: Config.contentHeight
            )
        }

        /// badge count frame
        if !badgeLabel.isHidden, viewData.badgeCount != nil {
            badgeLabel.frame = CGRect(
                x: offsetX + Config.horizontalSpace,
                y: (bounds.height - Config.badgeHeight) / 2,
                width: badgeWidth,
                height: Config.badgeHeight
            )
        }

        if !trailingIconView.isHidden {
            trailingIconView.frame = CGRect(
                x: containerView.frame.width - Config.trailingIconSize.width - Config.horizontalPadding,
                y: (bounds.height - Config.trailingIconSize.height) / 2,
                width: Config.trailingIconSize.width,
                height: Config.trailingIconSize.height)
        }

        if !separateLine.isHidden {
            let lintHeight = CGFloat(1.0 / UIScreen.main.scale)
            separateLine.frame = CGRect(
                x: 0,
                y: frame.height - lintHeight,
                width: bounds.width,
                height: lintHeight
            )
        }
    }

    @objc
    func clickSectionHeader() {
        tapSectionHandler?()
    }
    @objc
    func clickMore() {
        tapMoreHandler?()
    }

}

struct V3ListSingleUserInfo {
    // 头像
    var avatar: AvatarSeed
    // 名字
    var name: String
    // 宽度
    var nameWidth: CGFloat
}

private final class V3ListSingleUserView: UIView {

    var viewData: V3ListSingleUserInfo? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            isHidden = false
            avatar.setAvatarByIdentifier(
                viewData.avatar.avatarId,
                avatarKey: viewData.avatar.avatarKey,
                avatarViewParams: .init(sizeType: .size(ListConfig.Section.userSize.width), format: .webp)
            )
            nameLabel.text = viewData.name
        }
    }

    private lazy var avatar: BizAvatar = BizAvatar()

    private lazy var nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.font = ListConfig.Section.mainFont
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.numberOfLines = 1
        return nameLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(avatar)
        addSubview(nameLabel)
        backgroundColor = UIColor.ud.fillTag
        layer.cornerRadius = ListConfig.Section.contentHeight / 2
        layer.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let padding = ListConfig.Section.userLeftPadding
        avatar.frame = CGRect(
            origin: .init(x: padding, y: padding),
            size: ListConfig.Section.userSize
        )
        let left = avatar.frame.maxX + ListConfig.Section.userSpace
        nameLabel.frame = CGRect(
            x: left,
            y: 0,
            width: min(viewData?.nameWidth ?? 0, bounds.width - left),
            height: ListConfig.Section.contentHeight
        )
    }
}
