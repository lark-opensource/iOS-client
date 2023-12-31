//
//  ShortcutExpandMoreAvatarView.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/17.
//

import UIKit
import Foundation
import LarkBadge
import LarkModel
import LarkUIKit
import LarkBizAvatar

final class ShortcutExpandMoreAvatarView: UIView {

    let backgroundView = UIView()
    let arrowView = UIImageView()
    let badgeView = BadgeView(with: .none)

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(backgroundView)
        backgroundView.addSubview(arrowView)
        self.addSubview(badgeView)

        backgroundView.snp.makeConstraints { (make) in
            make.size.equalTo(ShortcutLayout.avatarSize)
            make.edges.equalToSuperview()
        }
        arrowView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalToSuperview().dividedBy(2.5)
        }
        badgeView.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.snp.right).offset(-ShortcutLayout.avatarSize / 2 * 0.29)
            make.centerY.equalTo(self.snp.top).offset(ShortcutLayout.avatarSize / 2 * 0.29)
            make.size.equalTo(19)
        }

        backgroundView.backgroundColor = UIColor.ud.bgFiller
        backgroundView.layer.cornerRadius = ShortcutLayout.avatarSize / 2
        backgroundView.layer.masksToBounds = true
        arrowView.image = Resources.shortcut_expand_more_icon.ud.withTintColor(UIColor.ud.iconN2)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
