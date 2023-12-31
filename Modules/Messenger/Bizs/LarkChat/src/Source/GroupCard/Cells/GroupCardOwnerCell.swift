//
//  GroupCardOwnerCell.swift
//  Lark
//
//  Created by Yuguo on 2017/10/27.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkCore
import LarkBizAvatar

final class GroupCardOwnerCell: UITableViewCell {
    fileprivate var avatarImageView = BizAvatar()
    private let avatarSize: CGFloat = 40

    var avatarTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        let label = UILabel.lu.labelWith(
            fontSize: 16,
            textColor: UIColor.ud.N900,
            text: BundleI18n.LarkChat.Lark_Legacy_ChatGroupOwner
        )
        self.contentView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(22)
            make.left.equalToSuperview().offset(16)
        }

        avatarImageView.lu.addTapGestureRecognizer(action: #selector(tappedActionWithAvatar), target: self)
        self.contentView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { (make) in
            make.top.equalTo(label.snp.bottom).offset(10)
            make.bottom.equalToSuperview().offset(-22)
            make.left.equalTo(label)
            make.size.equalTo(CGSize(width: avatarSize, height: avatarSize))
        }

        self.contentView.lu.addBottomBorder()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    fileprivate func tappedActionWithAvatar() {
        self.avatarTapped?()
    }
}
