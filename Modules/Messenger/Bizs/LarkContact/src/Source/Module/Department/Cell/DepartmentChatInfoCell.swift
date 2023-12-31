//
//  DepartmentChatInfoCell.swift
//  LarkContact
//
//  Created by 李勇 on 2019/7/3.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import LarkCore
import LarkBizAvatar
import AvatarComponent
import RustPB

protocol DepartmentChatInfoDelegate: AnyObject {
    func createOrEnterDidSelect(_ sender: UIButton, chatInfo: RustPB.Contact_V1_ChatInfo)
}

final class DepartmentChatInfoCell: UITableViewCell {
    weak var delegate: DepartmentChatInfoDelegate?
    private let avatarImageView = BizAvatar()
    private let avatarSize: CGFloat = 48
    private let titleLabel = UILabel()
    private let bottomDetailLabel = UILabel()
    private let rightButton = UIButton(type: .system)
    private let centerContentView = UIView()
    private var lastHighlightedDate: Date?
    private var chatInfo: RustPB.Contact_V1_ChatInfo?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        /// 中间内容区域
        self.centerContentView.layer.cornerRadius = 6
        self.centerContentView.layer.masksToBounds = true
        self.centerContentView.backgroundColor = UIColor.ud.N100
        self.contentView.addSubview(self.centerContentView)
        self.centerContentView.snp.makeConstraints { (make) in
            make.height.equalTo(70)
            make.center.equalToSuperview()
            make.left.equalTo(16)
        }
        /// 头像
        self.avatarImageView.layer.masksToBounds = true
        self.centerContentView.addSubview(self.avatarImageView)
        self.avatarImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(avatarSize)
            make.centerY.equalToSuperview()
            make.left.equalTo(14.5)
        }
        /// Team Group/群名称
        self.titleLabel.textColor = UIColor.ud.N900
        self.titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        self.titleLabel.numberOfLines = 1
        self.centerContentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(70.5)
            make.right.lessThanOrEqualTo(-94)
            make.top.equalTo(15)
        }
        /// Team Group/当前尚未创建部门群
        self.bottomDetailLabel.textColor = UIColor.ud.N500
        self.bottomDetailLabel.font = UIFont.systemFont(ofSize: 12)
        self.bottomDetailLabel.numberOfLines = 1
        self.centerContentView.addSubview(self.bottomDetailLabel)
        self.bottomDetailLabel.snp.makeConstraints { (make) in
            make.left.equalTo(70.5)
            make.right.lessThanOrEqualTo(-94)
            make.bottom.equalTo(-15.5)
        }
        /// Create/Enter
        self.rightButton.layer.masksToBounds = true
        self.rightButton.layer.cornerRadius = 4
        self.rightButton.backgroundColor = UIColor.ud.colorfulBlue
        self.rightButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        self.rightButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        self.rightButton.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        self.rightButton.addTarget(self, action: #selector(rightButtonClick), for: .touchUpInside)
        self.centerContentView.addSubview(self.rightButton)
        self.rightButton.snp.makeConstraints { (make) in
            make.width.equalTo(69.5)
            make.height.equalTo(30)
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        /// 点击时记录上次高亮的时间，改变颜色
        if highlighted {
            self.centerContentView.backgroundColor = UIColor.ud.N200
            self.lastHighlightedDate = Date()
            return
        }
        /// 复用/创建cell时会先被调用一次setHighlighted(false,xxx)方法，用可选值排除这种情况
        guard let lastDate = self.lastHighlightedDate else { return }
        /// 计算点击的时间，和0.5做差值
        let sapceTime = Date().timeIntervalSince1970 - lastDate.timeIntervalSince1970
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0, 0.5 - sapceTime)) {
            self.centerContentView.backgroundColor = UIColor.ud.N100
        }
    }

    @objc
    private func rightButtonClick(sender: UIButton) {
        guard let chatInfo = self.chatInfo else { return }
        self.delegate?.createOrEnterDidSelect(sender, chatInfo: chatInfo)
    }

    func setChatInfo(chatInfo: RustPB.Contact_V1_ChatInfo) {
        self.chatInfo = chatInfo
        if chatInfo.hasChat {
            self.avatarImageView.setAvatarByIdentifier(chatInfo.chat.id,
                                                       avatarKey: chatInfo.chat.avatarKey,
                                                       avatarViewParams: .init(sizeType: .size(avatarSize)))
            self.titleLabel.text = chatInfo.chat.name
            self.bottomDetailLabel.text = BundleI18n.LarkContact.Lark_Contacts_TeamGroupSupervisorCreateStatusName
            self.rightButton.setTitle(
                BundleI18n.LarkContact.Lark_Contacts_TeamGroupSupervisorEnterStatusAction,
                for: .normal
            )
        } else {
            self.avatarImageView.image = Resources.department_default_icon
            self.titleLabel.text = BundleI18n.LarkContact.Lark_Contacts_TeamGroupSupervisorCreateStatusName
            self.bottomDetailLabel.text = BundleI18n.LarkContact.Lark_Contacts_TeamGroupSupervisorCreateStatusTip
            self.rightButton.setTitle(
                BundleI18n.LarkContact.Lark_Contacts_TeamGroupSupervisorCreateStatusAction,
                for: .normal
            )
        }
    }
}
