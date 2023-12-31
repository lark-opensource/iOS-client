//
//  ShareMemberHeaderView.swift
//  Calendar
//
//  Created by heng zhu on 2019/3/25.
//

import UIKit
import Foundation
import CalendarFoundation
import SnapKit
import LarkBizAvatar
final class ShareMemberHeaderView: UIView {
    private let titleLable = UILabel.cd.textLabel()
    private let subTitleLable = UILabel.cd.subTitleLabel()
    private let avatar = AvatarView()

    init(name: String, group: String, isUserCountVisible: Bool, memberCount: Int, avatar: Avatar) {
        if isUserCountVisible {
            self.titleLable.text = "\(name)(\(memberCount))"
        } else {
            self.titleLable.text = name
        }

        self.subTitleLable.text = group
        self.avatar.setAvatar(avatar, with: 48)
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBody
        self.snp.makeConstraints { (make) in
            make.height.equalTo(68)
        }

        layout(avatar: self.avatar)
        layout(title: titleLable, leftItem: self.avatar.snp.right)
        layout(subTitle: subTitleLable, leftItem: self.avatar.snp.right)

    }

    private func layout(avatar: UIView) {
        addSubview(avatar)
        avatar.snp.makeConstraints { (make) in
            make.width.height.equalTo(48)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
    }

    private func layout(title: UIView, leftItem: ConstraintItem) {
        addSubview(title)
        title.snp.makeConstraints { (make) in
            make.left.equalTo(leftItem).offset(12)
            make.top.equalToSuperview().offset(11)
            make.right.equalToSuperview().offset(-16)
        }
    }

    private func layout(subTitle: UIView, leftItem: ConstraintItem) {
        addSubview(subTitle)
        subTitle.snp.makeConstraints { (make) in
            make.left.equalTo(leftItem).offset(12)
            make.bottom.equalToSuperview().offset(-11)
            make.right.equalToSuperview().offset(-16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
