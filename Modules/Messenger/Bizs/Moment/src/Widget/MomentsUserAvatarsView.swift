//
//  MomentsUserAvatarsView.swift
//  Moment
//
//  Created by liluobin on 2021/6/28.
//

import Foundation
import UIKit
import LarkBizAvatar

final class MomentsUserAvatarsView: UIView {
    let itemWidth: CGFloat
    var users: [MomentUser] = []
    init(itemWidth: CGFloat) {
        self.itemWidth = itemWidth
        super.init(frame: .zero)
    }

    var actualWidth: CGFloat {
        return itemWidth + 2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateUsers(_ users: [MomentUser]) {
        self.users = users
        self.subviews.forEach { $0.removeFromSuperview() }
        for (idx, user) in users.enumerated() {
            let view = UIView()
            view.backgroundColor = UIColor.ud.bgBase
            view.layer.cornerRadius = actualWidth / 2.0
            let avatar = BizAvatar(frame: CGRect(x: 1, y: 1, width: itemWidth, height: itemWidth))
            avatar.setAvatarByIdentifier(user.userID,
                                         avatarKey: user.avatarKey,
                                         scene: .Moments,
                                         avatarViewParams: .init(sizeType: .size(itemWidth)))
            view.addSubview(avatar)
            view.frame = CGRect(x: (actualWidth - 6) * CGFloat(idx), y: 0, width: actualWidth, height: actualWidth)
            self.addSubview(view)
        }
    }

    func suggestSize() -> CGSize {
        if users.isEmpty {
            return CGSize(width: .zero, height: actualWidth)
        }
        if users.count == 1 {
            return CGSize(width: actualWidth, height: actualWidth)
        }
        return CGSize(width: actualWidth + CGFloat(users.count - 1) * (actualWidth - 6), height: actualWidth)
    }
}
