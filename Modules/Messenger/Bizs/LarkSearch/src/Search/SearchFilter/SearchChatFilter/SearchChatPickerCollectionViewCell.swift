//
//  SearchItemPickerCollectionViewCell.swift
//  LarkSearch
//
//  Created by SuPeng on 4/24/19.
//

import Foundation
import UIKit
import LarkModel
import LarkCore
import LarkBizAvatar
import LarkSearchFilter

public final class SearchChatPickerCollectionViewCell: UICollectionViewCell {

    private let avatarView = BizAvatar()
    private let avatarSize: CGFloat = 30

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(avatarView)
        avatarView.avatar.ud.setMaskView()
        avatarView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: avatarSize, height: avatarSize))
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.image = nil
    }

    func set(item: SearchChatPickerItem) {
        avatarView.setAvatarByIdentifier(item.avatarID, avatarKey: item.avatarKey, avatarViewParams: .init(sizeType: .size(avatarSize)))
    }
}
