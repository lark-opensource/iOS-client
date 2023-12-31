//
//  SKAvatarGroupView.swift
//  SKUIKit
//
//  Created by Weston Wu on 2023/1/11.
//

import SnapKit
import SKResource
import UniverseDesignIcon
import UniverseDesignColor
import ByteWebImage

public extension SKAvatarGroupView {
    struct Config {
        // 注意需要加上外边框的宽度
        public let avatarWidth: CGFloat
        // 头像间距，负值表示重叠
        public let avatarSpacing: CGFloat
        // 最大头像数量
        public let maxAvatarCount: Int

        public init(avatarWidth: CGFloat, avatarSpacing: CGFloat, maxAvatarCount: Int) {
            self.avatarWidth = avatarWidth
            self.avatarSpacing = avatarSpacing
            self.maxAvatarCount = maxAvatarCount
        }

        public static var searchFilter: Config {
            Config(avatarWidth: 30,
                   avatarSpacing: -10,
                   maxAvatarCount: 6)
        }
    }

    enum AvatarInfo {
        case icon(key: UDIconType)
        case image(UIImage)
        case url(URL)
        case avatar(key: String, entityID: String)
    }
}

open class SKAvatarGroupView: UIView {
    public let config: Config

    public private(set) var containerView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fill
        view.alignment = .fill
        return view
    }()

    public init(config: Config) {
        self.config = config
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func reset() {
        containerView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        isUserInteractionEnabled = false
    }

    public func update(items: [AvatarInfo], totalCount: Int? = nil) {
        reset()
        let avatarCount = totalCount ?? items.count
        containerView.spacing = config.avatarSpacing
        let needMoreView = items.count > config.maxAvatarCount
        let visableAvatarItems = needMoreView ? items.prefix(config.maxAvatarCount - 1) : items.prefix(config.maxAvatarCount)
        visableAvatarItems.forEach { avatarInfo in
            let avatarView = AvatarContainerView()
            containerView.addArrangedSubview(avatarView)
            avatarView.snp.makeConstraints { make in
                make.width.height.equalTo(config.avatarWidth)
            }
            avatarView.layer.cornerRadius = config.avatarWidth / 2
            avatarView.layer.ud.setBorderColor(UDColor.bgFloat)
            switch avatarInfo {
            case let .icon(key):
                avatarView.avatar.image = UDIcon.getIconByKey(key, size: CGSize(width: 20, height: 20))
                avatarView.avatar.contentMode = .center
                avatarView.backgroundColor = UDColor.W200
            case let .image(image):
                avatarView.avatar.image = image
            case let .url(url):
                avatarView.avatar.kf.setImage(with: url,
                                              placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder)
            case let .avatar(key, entityID):
                avatarView.avatar.bt.setLarkImage(with: .avatar(key:key, entityID: entityID),
                                                  placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder)
            }
        }

        if needMoreView {
            let moreView = MoreAvatarView()
            containerView.addArrangedSubview(moreView)
            moreView.snp.makeConstraints { make in
                make.width.height.equalTo(config.avatarWidth)
            }
            moreView.layer.cornerRadius = config.avatarWidth / 2
            moreView.layer.ud.setBorderColor(UDColor.bgFloat)
            moreView.update(number: avatarCount - config.maxAvatarCount + 1)
        }
    }
}
