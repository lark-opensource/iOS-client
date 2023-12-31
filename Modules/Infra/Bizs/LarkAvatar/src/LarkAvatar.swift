//
//  LarkAvatar.swift
//  LarkAvatar
//
//  Created by qihongye on 2020/2/11.
//

import UIKit
import Foundation
import UniverseDesignColor
import ByteWebImage
import Kingfisher

public struct MiniIconProps {
    public enum TypeEnum {
        case unknown
        case dynamicURL(URL)
        case dynamicKey(String)
        case dynamicIcon(UIImage)
        case thread
        case topic
        case ppt
        case docs
        case sheet
        case mindmap
        case table
        case micoApp
    }

    public var type: TypeEnum
    public var placeholder: UIImage?

    public init(_ type: TypeEnum = .unknown, placeholder: UIImage? = nil) {
        self.type = type
        self.placeholder = placeholder
    }
}

public struct BadgeProps {
    public enum FeedType {
        case done
        case inbox
    }

    public enum StyleType {
        case weakRemind
        case strongRemind
    }

    public var badgeStyle: StyleType
    public var maxCount: Int = 999
    public var feedType: FeedType
    public var count: Int
    public var isAt: Bool
    public var isRemind: Bool
    public var isUrgent: Bool

    public init(badgeStyle: StyleType,
                feedType: FeedType,
                count: Int,
                isAt: Bool,
                isRemind: Bool,
                isUrgent: Bool,
                maxCount: Int = 999) {
        self.badgeStyle = badgeStyle
        self.feedType = feedType
        self.count = count
        self.isAt = isAt
        self.isRemind = isRemind
        self.isUrgent = isUrgent
        self.maxCount = maxCount
    }
}

public struct LarkAvatarProps {
    public var avatarKey: String
    public var image: UIImage?
    public var placeholder: UIImage?
    public var isUrgent: Bool
    public var badge: BadgeProps?
    public var miniIcon: MiniIconProps?
    public var processor: ImageProcessor?

    public init(avatarKey: String = "",
                image _: UIImage? = nil,
                placeholder: UIImage? = nil,
                isUrgent: Bool,
                badge: BadgeProps? = nil,
                miniIcon: MiniIconProps? = nil,
                processor: ImageProcessor? = nil) {
        self.avatarKey = avatarKey
        self.placeholder = placeholder
        self.isUrgent = isUrgent
        self.badge = badge
        self.miniIcon = miniIcon
        self.processor = processor
    }
}

open class LarkAvatarView: UIView {
    private lazy var base: LarkBaseAvatarView = {
        let avatar = LarkBaseAvatarView(frame: CGRect(origin: .zero, size: CGSize(width: 48, height: 48)))
        avatar.badgeSize = 18
        return avatar
    }()

    public var badgeView: LarkBadgeView {
        return base.topRightBadgeView
    }

    public var badgeSize: CGFloat {
        get {
            return base.badgeSize
        }
        set {
            base.badgeSize = newValue
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(base)
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        base.frame = bounds
    }

    public func setProps(_ props: LarkAvatarProps?) {
        if let isUrgent = props?.isUrgent {
            base.borderView.isHidden = !isUrgent
        } else {
            base.borderView.isHidden = true
        }
        if let avatarKey = props?.avatarKey, !avatarKey.isEmpty {
            setAvatar(avatarKey: avatarKey, placeholder: props?.placeholder, processor: props?.processor)
        } else {
            setAvatar(image: props?.image)
        }
        setBadge(badgeProps: props?.badge)
        setMiniIcon(props?.miniIcon)
    }

    public func setAvatar(image: UIImage?) {
        base.image = image
    }

    public func setAvatar(avatarKey: String, placeholder: UIImage? = nil, processor: ImageProcessor? = nil) {
        // TODO: 部分接口返回中rust没有处理好avatarKey,此处做容错，待rust修正后去除
        var fixedKey = avatarKey.replacingOccurrences(of: "lark.avatar/", with: "")
        fixedKey = fixedKey.replacingOccurrences(of: "mosaic-legacy/", with: "")
        base.imageView.bt.setLarkImage(with: .avatar(key: fixedKey,
                                                     entityID: "",
                                                     params: .defaultMiddle),
                                       placeholder: placeholder,
                                       trackStart: {
                                        return TrackInfo(scene: .Chat, fromType: .avatar)
                                       })
    }

    public func setAvatar(url: URL, placeholder: UIImage? = nil) {
        let url = url.absoluteString
        base.imageView.bt.setLarkImage(with: .default(key: url),
                                       placeholder: placeholder,
                                       trackStart: {
                                        return TrackInfo(scene: .Chat, fromType: .avatar)
                                       })
    }

    public func setBadge(badge: Badge?) {
        base.setBadge(topRight: badge)
    }

    public func setBadge(badgeProps: BadgeProps?) {
        defer {
            setNeedsLayout()
        }
        guard let badgeProps = badgeProps else {
            base.setBadge(topRight: nil)
            return
        }
        if badgeProps.isUrgent {
            base.setBadge(topRight: Badge(type: .icon(SetBadgeIcon(
                icon: Resources.badgeUrgentIcon,
                expectSize: Resources.badgeUrgentIcon.size
            ))))
            return
        }
        if badgeProps.isAt {
            base.setBadge(topRight: Badge(type: .icon(SetBadgeIcon(
                icon: Resources.badgeAtIcon,
                expectSize: Resources.badgeAtIcon.size
            ))))
            return
        }
        // swiftlint:disable empty_count
        if badgeProps.count <= 0 {
            base.setBadge(topRight: nil)
            return
        }
        if badgeProps.isRemind {
            if badgeProps.count > badgeProps.maxCount {
                switch badgeProps.feedType {
                case .done:
                    base.setBadge(topRight: Badge(
                        type: .icon(SetBadgeIcon(
                            icon: Resources.badgeDoneMoreIcon,
                            expectSize: Resources.badgeDoneMoreIcon.size
                        ))
                    ))
                case .inbox:
                    base.setBadge(topRight: Badge(
                        type: .icon(SetBadgeIcon(
                            icon: Resources.badgeInboxMoreIcon,
                            expectSize: Resources.badgeInboxMoreIcon.size
                        ))
                    ))
                }
                return
            }
            switch badgeProps.feedType {
            case .done:
                base.setBadge(topRight: Badge(
                    type: .text("\(badgeProps.count)"),
                    border: Border(width: 1.5, color: .white),
                    textColor: UIColor.ud.colorfulRed,
                    backgroundColor: UIColor.ud.R100
                ))
            case .inbox:
                base.setBadge(topRight: Badge(
                    type: .text("\(badgeProps.count)"),
                    border: Border(width: 1.5, color: .white),
                    textColor: UIColor.ud.N00,
                    backgroundColor: UIColor.ud.colorfulRed
                ))
            }
            return
        }
        if badgeProps.feedType == .done {
            base.setBadge(topRight: Badge(type: .icon(SetBadgeIcon(
                icon: Resources.badgeMuteIcon,
                expectSize: Resources.badgeMuteIcon.size
            ))))
            return
        }
        switch badgeProps.badgeStyle {
        case .weakRemind:
            if badgeProps.count > badgeProps.maxCount {
                base.setBadge(topRight: Badge(type: .icon(SetBadgeIcon(
                    icon: Resources.badgeInboxMuteMoreIcon,
                    expectSize: Resources.badgeInboxMuteMoreIcon.size
                ))))
                return
            }
            base.setBadge(topRight: Badge(
                type: .text("\(badgeProps.count)"),
                border: Border(width: 1.5, color: .white),
                textColor: UIColor.ud.N00,
                backgroundColor: UIColor.ud.N400
            ))
        case .strongRemind:
            base.setBadge(topRight: Badge(type: .icon(SetBadgeIcon(
                icon: Resources.badgeRedMuteIcon,
                expectSize: Resources.badgeRedMuteIcon.size
            ))))
        }
    }

    public func setMiniIcon(_ miniIcon: MiniIconProps?) {
        base.setBadge(bottomRight: Self.convertToBadge(miniIcon))
        setNeedsLayout()
    }

    @inline(__always)
    static func convertToBadge(_ miniIcon: MiniIconProps?) -> Badge? {
        guard let miniIcon = miniIcon else {
            return nil
        }
        var badgeType: Badge.TypeEnum
        switch miniIcon.type {
        case .unknown:
            return nil
        case let .dynamicIcon(image):
            badgeType = .icon(SetBadgeIcon(icon: image))
        case let .dynamicKey(key):
            badgeType = .icon(SetBadgeIcon(iconKey: key, icon: miniIcon.placeholder))
        case let .dynamicURL(url):
            let url = url.absoluteString
            badgeType = .icon(SetBadgeIcon(iconURL: url, icon: miniIcon.placeholder))
        case .docs:
            badgeType = .icon(SetBadgeIcon(icon: Resources.doc))
        case .ppt:
            badgeType = .icon(SetBadgeIcon(icon: Resources.ppt))
        case .mindmap:
            badgeType = .icon(SetBadgeIcon(icon: Resources.mindmap))
        case .sheet:
            badgeType = .icon(SetBadgeIcon(icon: Resources.sheet))
        case .table:
            badgeType = .icon(SetBadgeIcon(icon: Resources.table))
        case .micoApp:
            badgeType = .icon(SetBadgeIcon(icon: Resources.micoApp))
        case .thread:
            badgeType = .icon(SetBadgeIcon(icon: Resources.thread))
        case .topic:
            badgeType = .icon(SetBadgeIcon(icon: Resources.topic))
        }
        return Badge(type: badgeType, border: Border(width: 1.5, color: .white))
    }
}
