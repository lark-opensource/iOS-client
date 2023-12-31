//
//  LarkBaseAvatarView.swift
//  LarkAvatar
//
//  Created by qihongye on 2020/2/12.
//

import UIKit
import Foundation

public struct Border {
    let width: CGFloat
    let color: UIColor

    public init(width: CGFloat = 0, color: UIColor) {
        self.width = width
        self.color = color
    }
}

open class LarkBaseAvatarView: UIView {
    public lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    public lazy var borderView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: 48, height: 48)))
        imageView.image = Resources.innerBorder
        imageView.isHidden = true
        return imageView
    }()

    public lazy var topRightBadgeView: LarkBadgeView = {
        let badge = LarkBadgeView()
        badge.isHidden = true
        badge.layer.cornerRadius = badgeSize / 2
        badge.textEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: 3)
        badge.textFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        badge.textColor = UIColor.white
        badge.textAlignment = .center
        badge.layer.borderColor = UIColor.white.cgColor
        badge.layer.borderWidth = 1.5
        badge.backgroundColorStable = true
        return badge
    }()

    public lazy var bottomRightBadgeView: LarkBadgeView = {
        let badge = LarkBadgeView()
        badge.isHidden = true
        badge.layer.cornerRadius = miniIconSize / 2
        badge.layer.borderColor = UIColor.white.cgColor
        badge.layer.borderWidth = 1.5
        return badge
    }()

    public var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
        }
    }

    public var badgeSize: CGFloat = 18 {
        didSet {
            topRightBadgeView.layer.cornerRadius = badgeSize / 2
            setNeedsLayout()
        }
    }

    public var miniIconSize: CGFloat = 21 {
        didSet {
            bottomRightBadgeView.layer.cornerRadius = miniIconSize / 2
            setNeedsLayout()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        addSubview(borderView)
        addSubview(topRightBadgeView)
        addSubview(bottomRightBadgeView)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        borderView.frame = bounds
        imageView.frame = bounds
        imageView.layer.cornerRadius = min(bounds.width, bounds.height) / 2
        /// top -3 right -2
        topRightBadgeView.sizeToFit()
        topRightBadgeView.frame.size.height = badgeSize
        topRightBadgeView.frame.size.width = max(badgeSize, topRightBadgeView.frame.size.width)
        topRightBadgeView.frame.origin = CGPoint(
            x: bounds.width + 2 - topRightBadgeView.frame.width,
            y: -3
        )
        /// bottom -3 right -2
        bottomRightBadgeView.frame = CGRect(
            x: bounds.width + 2 - miniIconSize,
            y: bounds.height + 3 - miniIconSize,
            width: miniIconSize,
            height: miniIconSize
        )
    }

    public func setBadge(topRight: Badge?) {
        if let badge = topRight {
            topRightBadgeView.isHidden = false
            topRightBadgeView.setBadge(badge)
            setNeedsLayout()
        } else {
            topRightBadgeView.isHidden = true
        }
    }

    public func setBadge(bottomRight: Badge?) {
        if let badge = bottomRight {
            bottomRightBadgeView.isHidden = false
            bottomRightBadgeView.setBadge(badge)
            setNeedsLayout()
        } else {
            bottomRightBadgeView.isHidden = true
        }
    }

    public func setBadge(topRight: Badge? = nil, bottomRight: Badge? = nil) {
        setBadge(topRight: topRight)
        setBadge(bottomRight: bottomRight)
    }
}
