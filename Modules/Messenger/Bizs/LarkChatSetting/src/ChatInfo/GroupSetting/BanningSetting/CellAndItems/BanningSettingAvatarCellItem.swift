//
//  BanningSettingAvatarCellItem.swift
//  LarkChat
//
//  Created by kkk on 2019/3/11.
//

import Foundation
import UIKit
import LarkCore
import LarkBizAvatar

struct BanningSettingAvatarItem: BanningSettingItem {
    var id: String
    var avatarKay: String
    var identifier: String
}

final class BanningSettingAvatarCell: UIControl, BanningSettingCell {
    private(set) var item: BanningSettingItem?
    private let avatarView = BizAvatar()
    private let avatarSize: CGFloat = 32

    override init(frame: CGRect) {
        super.init(frame: frame)

        avatarView.layer.cornerRadius = 16
        avatarView.layer.masksToBounds = true
        avatarView.isUserInteractionEnabled = false
        self.addSubview(avatarView)
        avatarView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
            maker.width.height.equalTo(avatarSize).priority(.required)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(item: BanningSettingItem) {
        guard let item = item as? BanningSettingAvatarItem else {
            assert(false, "item type error")
            return
        }
        self.item = item
        avatarView.setAvatarByIdentifier(item.id,
                                         avatarKey: item.avatarKay,
                                         scene: .Chat,
                                         avatarViewParams: .init(sizeType: .size(avatarSize)))
    }
}
