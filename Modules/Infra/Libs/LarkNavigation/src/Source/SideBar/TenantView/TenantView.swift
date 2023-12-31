//
//  TenantView.swift
//  LarkNavigation
//
//  Created by Supeng on 2021/6/2.
//

import UIKit
import Foundation
import ByteWebImage
import UniverseDesignColor
import UniverseDesignBadge
import UniverseDesignIcon

final class TenantView: UITableViewCell {
    static let resuseIdentifier = String(ObjectIdentifier(TenantView.self).hashValue)

    private let avatarSize: CGFloat = 48
    private let avatarRadius: CGFloat = 8

    private(set) var currentTenantItem: Tenant?

    private let icon = UIImageView()
    private let name = UILabel()
    private let exclamationMark = UIImageView()
    private let exclamationMarkBgView = UIView()
    private let badgeView = UDBadge(config: UDBadgeConfig(style: .custom(UDColor.colorfulRed), contentStyle: .custom(UDColor.primaryOnPrimaryFill)))
    private let indicatorView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {

        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = UDColor.bgBase

        let layoutGuide = UILayoutGuide()
        contentView.addLayoutGuide(layoutGuide)
        layoutGuide.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.center.equalToSuperview()
        }

        icon.layer.cornerRadius = avatarRadius
        icon.layer.masksToBounds = true
        contentView.addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.top.centerX.equalTo(layoutGuide)
            make.size.equalTo(CGSize(width: avatarSize, height: avatarSize))
        }
        icon.addPointer(.lift)

        name.textAlignment = .center
        name.font = UIFont.systemFont(ofSize: 10)
        name.textColor = UIColor.ud.N500
        contentView.addSubview(name)
        name.snp.makeConstraints { (make) in
            make.left.equalTo(12)
            make.right.equalTo(-12)
            make.top.equalTo(icon.snp.bottom).offset(6)
            make.bottom.centerX.equalTo(layoutGuide)
        }

        exclamationMarkBgView.backgroundColor = UDColor.primaryOnPrimaryFill
        exclamationMarkBgView.layer.cornerRadius = 8
        exclamationMarkBgView.layer.masksToBounds = true
        contentView.addSubview(exclamationMarkBgView)
        exclamationMarkBgView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 16, height: 16))
            make.right.equalTo(icon).offset(6)
            make.top.equalTo(icon.snp.top).offset(-6)
        }

        exclamationMark.image = BundleResources.LarkNavigation.exlamationMark.ud.withTintColor(UDColor.textDisabled)
        exclamationMarkBgView.addSubview(exclamationMark)
        exclamationMark.snp.makeConstraints { $0.edges.equalToSuperview() }

        contentView.addSubview(badgeView)
        badgeView.snp.makeConstraints { (make) in
            make.right.equalTo(icon).offset(6)
            make.top.equalTo(icon.snp.top).offset(-6)
        }

        indicatorView.backgroundColor = UIColor.ud.bgPricolor
        indicatorView.layer.masksToBounds = true
        indicatorView.layer.cornerRadius = avatarRadius / 2
        indicatorView.isHidden = true
        contentView.addSubview(indicatorView)
        indicatorView.snp.makeConstraints { (make) in
            make.centerY.equalTo(icon)
            make.left.equalToSuperview().offset(-avatarRadius / 2)
            make.size.equalTo(CGSize(width: avatarRadius, height: avatarSize))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let placeholderImage = UIImage.ud.fromPureColor(UIColor.ud.N300)

    func set(tenantItem: Tenant) {
        currentTenantItem = tenantItem

        name.text = tenantItem.name
        let resource: LarkImageResource = .avatar(key: tenantItem.avatarKey, entityID: tenantItem.id, params: .defaultMiddle)
        if let image = LarkImageService.shared.image(with: resource) {
            /// ByteWebImage 会先设置placeholder，再查找图或者下载图再设置image，导致展示时候有闪动，
            /// 先查下缓存，如果找到直接设置，可以避免这个问题
            /// 后续待ByteWebImage优化后可改回正常设置即可
            icon.bt.setLarkImage(with: .default(key: ""), placeholder: image)
        } else {
            icon.bt.setLarkImage(with: resource, placeholder: placeholderImage)
        }
        exclamationMarkBgView.isHidden = !tenantItem.showExclamationMark
        indicatorView.isHidden = !tenantItem.showIndicator
        if !tenantItem.showExclamationMark {
            switch tenantItem.badge {
            case .new:
                badgeView.config.type = .text
                badgeView.config.text = "New"
                badgeView.isHidden = false
            case .none:
                badgeView.isHidden = true
            case .number(let number):
                badgeView.config.type = .number
                badgeView.config.number = number
                badgeView.isHidden = false
            }
        } else {
            badgeView.isHidden = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        icon.bt.setLarkImage(with: .default(key: ""), placeholder: nil)
    }
}
